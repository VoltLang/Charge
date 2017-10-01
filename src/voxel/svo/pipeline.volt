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
	camPosition: math.Point3f; frame: u32;
	pointScale: f32;


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
	mCounterBuffer: GLuint;

	mInBuffer: GLuint;
	mOutBuffer: GLuint;

	mSortShader: gfx.Shader;


public:
	this(data: Data)
	{
		this.data = data;
		super("test", new gfx.Counters("test"));

		comp, frag, vert: string;

		comp = import("voxel/walk-sort.comp.glsl");

		mSortShader = new gfx.Shader(name, comp);


		// Create the storage for the atomic buffer.
		glCreateBuffers(1, &mCounterBuffer);
		glNamedBufferStorage(mCounterBuffer, 8 * 4, null, GL_DYNAMIC_STORAGE_BIT);

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


		glCheckError();
		glClearNamedBufferData(mCounterBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(mInBuffer, 0, 16, cast(void*)[0, 0, 0, input.frame].ptr);

		// General bindigns.
		glBindTextureUnit(0, data.texture);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mCounterBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, mInBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, mOutBuffer);

		// Sort shader.
		mSortShader.bind();
		mSortShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		mSortShader.matrix4("uMatrix", 1, false, ref state.matrix);
		mSortShader.float4("uPlanes".ptr, 4, &state.planes[0].a);
		glDispatchCompute(1u, 1u, 1u);
		mSortShader.unbind();

		// Unbind general bindings.
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);

		glBindTextureUnit(0, data.texture);

		// Debug
		glCheckError();

		io.output.writefln("%s %s", input.frame, debugCounter(0));
		io.output.flush();
	}


private:
	fn debugCounter(src: u32) u32
	{
		glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
		val: u32;
		offset := cast(GLintptr)(src * 4);
		glGetNamedBufferSubData(mCounterBuffer, offset, 4, cast(void*)&val);
		return val;
	}
}
