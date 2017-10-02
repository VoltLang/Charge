// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.pipeline;

import io = watt.io;

import watt.text.string;
import watt.text.format;
import watt.math.floating;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.entity;
import voxel.svo.shaders;
import voxel.svo.buffers;


/*!
 * Checks if we can run voxel graphics code, return null on success.
 */
fn checkGraphics() string
{
	str: string;

	// Need OpenGL 4.5 now.
	if (!GL_VERSION_4_5) {
		str ~= "Need at least GL 4.5\n";
	}

	// For texture functions.
	if (!GL_ARB_texture_storage && !GL_VERSION_4_5) {
		str ~= "Need GL_ARB_texture_storage or OpenGL 4.5\n";
	}

	// For samplers functions.
	if (!GL_ARB_sampler_objects && !GL_VERSION_3_3) {
		str ~= "Need GL_ARB_sampler_objects or OpenGL 3.3\n";
	}

	// For shaders.
	if (!GL_ARB_ES2_compatibility) {
		str ~= "Need GL_ARB_ES2_compatibility\n";
	}
	if (!GL_ARB_explicit_attrib_location) {
		str ~= "Need GL_ARB_explicit_attrib_location\n";
	}
	if (!GL_ARB_shader_ballot) {
		str ~= "Need GL_ARB_shader_ballot\n";
	}
	if (!GL_ARB_shader_atomic_counter_ops && !GL_AMD_shader_atomic_counter_ops) {
		str ~= "Need GL_ARB_shader_atomic_counter_ops\n";
		str ~=  " or GL_AMD_shader_atomic_counter_ops\n";
	}

	return str;
}

/*!
 * Input to the draw call that renders the SVO.
 */
struct Draw
{
	camMVP: math.Matrix4x4d;
	cullMVP: math.Matrix4x4d;
	camPos: math.Point3f; pad0: f32;
	cullPos: math.Point3f; pad1: f32;
	frame, targetWidth, targetHeight: u32; fov: f32;
}

/*!
 * A single SVO rendering pipeline.
 */
abstract class Pipeline
{
public:
	counters: gfx.Counters;
	name: string;


public:
	this(name: string, counters: gfx.Counters)
	{
		this.name = name;
		this.counters = counters;
	}

	abstract fn close();
	abstract fn draw(ref input: Draw);
}

struct TestState
{
public:
	matrix: math.Matrix4x4f;
	planes: math.Planef[4];
	camPosition: math.Point3f; pointScale: f32;
	frame: u32;


	fn setFrom(ref input: Draw)
	{
		frustum: math.Frustum;
		frustum.setFromUntransposedGL(ref input.cullMVP);
		height := cast(f64)input.targetHeight;
		fov := radians(cast(f64)input.fov);

		matrix.setToAndTranspose(ref input.camMVP);
		camPosition = input.cullPos;
		planes[0].setFrom(ref frustum.p[0]);
		planes[1].setFrom(ref frustum.p[1]);
		planes[2].setFrom(ref frustum.p[2]);
		planes[3].setFrom(ref frustum.p[3]);
		frame = input.frame;
		pointScale = cast(f32)(height / (2.0 * tan(fov / 2.0)));
	}
}

/*!
 * A single SVO rendering pipeline.
 */
class TestPipeline : Pipeline
{
public:
	data: Data;


protected:
	mStore: ShaderStore;

	mDataBuffer: GLuint;
	mAtomicBuffer: GLuint;
	mCounterBuffer: GLuint;

	mDrawIndirect: GLuint;
	mDispatchIndirect: GLuint;

	mInBuffer: GLuint;
	mOutBuffer: GLuint;
	mArrayVAO: GLuint;

	mSort: gfx.Shader[5];
	mPoints: gfx.Shader;

	enum DataBufferSize = 4 * 128;
	enum AtomicBufferSize = 4 * 8;
	enum CounterBufferSize = 4 * 64;
	enum DrawIndirectSize = 4 * 4;
	enum DispatchIndirectSize = 4 * 3;


public:
	this(data: Data)
	{
		this.data = data;
		this.mStore = getStore(ref data.create);
		super("test", new gfx.Counters("init", "walk", "walk", "walk", "walk", "double", "points"));


		mSort[0] = mStore.makeWalkSimpleShader(src: 2, dst: 3, counterIndex: 1, powerStart: 0, powerLevels: 3);
		mSort[1] = mStore.makeWalkSortShader(src: 3, dst: 2, counterIndex: 2, powerStart: 3);
		mSort[2] = mStore.makeWalkSortShader(src: 2, dst: 3, counterIndex: 3, powerStart: 5);
		mSort[3] = mStore.makeWalkSortShader(src: 3, dst: 2, counterIndex: 4, powerStart: 7);
		mSort[4] = mStore.makeListDoubleShader(src: 2, dst: 3, powerStart: 9);
		mPoints = mStore.makePointsShader(src: 3, powerStart: 11);

		// Setup the dummy arrays VAO.
		glCreateVertexArrays(1, &mArrayVAO);

		// Create the storage for the atmic buffer.
		glCreateBuffers(1, &mAtomicBuffer);
		glNamedBufferStorage(mAtomicBuffer, AtomicBufferSize, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Create the storage for the command buffer.
		glCreateBuffers(1, &mDispatchIndirect);
		glNamedBufferStorage(mDispatchIndirect, DispatchIndirectSize, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mDispatchIndirect, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Create the storage for the command buffer.
		glCreateBuffers(1, &mDrawIndirect);
		glNamedBufferStorage(mDrawIndirect, DrawIndirectSize, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mDrawIndirect, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Create the storage for the counter buffer.
		glCreateBuffers(1, &mCounterBuffer);
		glNamedBufferStorage(mCounterBuffer, CounterBufferSize, null, GL_DYNAMIC_STORAGE_BIT);

		// Create the storage for the data buffer.
		glCreateBuffers(1, &mDataBuffer);
		glNamedBufferStorage(mDataBuffer, DataBufferSize, null, GL_DYNAMIC_STORAGE_BIT);

		// Really big data buffer.
		glCreateBuffers(1, &mInBuffer);
		glNamedBufferStorage(mInBuffer, 0x0800_0000, null, GL_DYNAMIC_STORAGE_BIT);
		glCreateBuffers(1, &mOutBuffer);
		glNamedBufferStorage(mOutBuffer, 0x0800_0000, null, GL_DYNAMIC_STORAGE_BIT);
	}

	override fn close()
	{

	}

	override fn draw(ref input: Draw)
	{
		frustum: math.Frustum;
		frustum.setFromUntransposedGL(ref input.cullMVP);
		height := cast(f64)input.targetHeight;
		fov := radians(cast(f64)input.fov);

		state: TestState;
		state.setFrom(ref input);

		// Clear any error state.
		glCheckError();

		// General bindigns.
		glBindTextureUnit(0, data.texture);

		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, mDrawIndirect);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, mDispatchIndirect);
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, mAtomicBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mCounterBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, mDataBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, mInBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, mOutBuffer);
		glBindVertexArray(mArrayVAO);

		// Clear and setup buffers.
		counters.start(0);
		glClearNamedBufferData(mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glClearNamedBufferData(mCounterBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(mDrawIndirect, 0, 4 * 4, cast(void*)[0, 1, 0, 0].ptr);
		glNamedBufferSubData(mDispatchIndirect, 0, 4 * 3, cast(void*)[0, 1, 1].ptr);
		glNamedBufferSubData(mInBuffer, 0, 4 * 3, cast(void*)[0, 0, input.frame].ptr);
		glNamedBufferSubData(mDataBuffer, 0, 4 * (16 + 16 + 4), cast(void*)&state);
		glNamedBufferSubData(mCounterBuffer, 0, 4, cast(void*)[1].ptr);
		counters.stop(0);

		// 1st sort shader.
		counters.start(1);
		runSort(0);
		counters.stop(1);

		// 2nd sort shader.
		counters.start(2);
		runSort(1);
		counters.stop(2);

		// 3rd sort shader.
		counters.start(3);
		runSort(2);
		counters.stop(3);

		// 4th sort shader.
		counters.start(4);
		runSort(3);
		counters.stop(4);

		// 5th sort shader.
		counters.start(5);
		runDouble(ref state, 4);
		counters.stop(5);

		// Run the points shader
		counters.start(6);
		runPoints(ref state, 3);
		counters.stop(6);

		// Unbind all state
		glUseProgram(0);
		glBindVertexArray(0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, 0);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, 0);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);

		glBindTextureUnit(0, data.texture);

		// Debug
		glCheckError();
	}


protected:
	fn runSort(num: u32)
	{
		// Copy the counter from the previous run.
		off := cast(GLintptr)(num * 4);
		glCopyNamedBufferSubData(mCounterBuffer, mDispatchIndirect, off, 0, 4);

		mSort[num].bind();
		glDispatchComputeIndirect(0u);
	}

	fn runDouble(ref state: TestState, num: u32)
	{
		// Copy the counter from the previous run.
		off := cast(GLintptr)(num * 4);
		glCopyNamedBufferSubData(mCounterBuffer, mDispatchIndirect, off, 0, 4);

		mSort[4].bind();
		mSort[4].float3("uCameraPos".ptr, state.camPosition.ptr);
		mSort[4].matrix4("uMatrix", 1, false, ref state.matrix);
		mSort[4].float1("uPointScale".ptr, state.pointScale);
		glDispatchComputeIndirect(0u);
	}

	fn runPoints(ref state: TestState, num: u32)
	{
		// Copy the counter from the previous run.
		off := cast(GLintptr)(num * 4);
		glCopyNamedBufferSubData(mAtomicBuffer, mDrawIndirect, off, 0, 4);

		mPoints.bind();
		mPoints.float3("uCameraPos".ptr, state.camPosition.ptr);
		mPoints.matrix4("uMatrix", 1, false, ref state.matrix);
		mPoints.float1("uPointScale".ptr, state.pointScale);
		glEnable(GL_PROGRAM_POINT_SIZE);
		glDrawArraysIndirect(GL_POINTS, null);
		glDisable(GL_PROGRAM_POINT_SIZE);
		glCheckError();
	}


private:
	fn debugCounter(src: u32) u32
	{
		val: u32[1];
		readBuffer(mCounterBuffer, src, val);
		return val[0];
	}

	fn debugAtomic(src: u32) u32
	{
		val: u32[1];
		readBuffer(mAtomicBuffer, src, val);
		return val[0];
	}

	fn printCounters()
	{
		val: u32[8];
		readBuffer(mCounterBuffer, 0, val);
		io.output.writef( "| %8s | %8s | %8s | %8s |", val[0], val[1], val[2], val[3]);
		io.output.writefln(" %8s | %8s | %8s | %8s |", val[4], val[5], val[6], val[7]);
	}

	fn printData(slot: u32)
	{
		val: u32[4];
		readBuffer(mOutBuffer, slot * 4, val);
		io.output.writefln("| %08x | %08x | %08x | %08x |", val[0], val[1], val[2], val[3]);
	}

	fn readBuffer(buf: GLuint, offset: u32, data: scope u32[])
	{
		glOffset := cast(GLintptr)(offset * 4);
		glSize := cast(GLsizei)(data.length * 4);
		glPtr := cast(void*)data.ptr;
		glGetNamedBufferSubData(buf, glOffset, glSize, glPtr);
	}
}
