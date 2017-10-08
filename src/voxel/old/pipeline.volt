// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.old.pipeline;

import io = watt.io;

import watt.text.string;
import watt.text.format;
import watt.math.floating;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.buffers;

import voxel.old.shaders;


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
	frame, numLevels, targetWidth, targetHeight: u32; fov: f32;
}

/*!
 * A single SVO rendering pipeline.
 */
abstract class Pipeline
{
public:
	name: string;


protected:
	mTimeTrackerRoot: gfx.TimeTracker;


public:
	this(name: string)
	{
		this.name = name;
		this.mTimeTrackerRoot = new gfx.TimeTracker("voxels (" ~ name ~ ")");
	}

	abstract fn close();

	fn draw(ref input: Draw)
	{
		mTimeTrackerRoot.start();
		doDraw(ref input);
		mTimeTrackerRoot.stop();
	}

	abstract fn doDraw(ref input: Draw);
}

/*!
 * A SVO rendering pipeline that uses stages.
 */
class StepPipeline : Pipeline
{
public:
	enum Kind
	{
		CubePoint,
		Points0,
		Points1,
		Raycube,
		Num,
	}


protected:
	mTimeTrackers: gfx.TimeTracker[];

	mOctTexture: GLuint;

	mElementsVAO: GLuint;
	mArrayVAO: GLuint;

	mIndexBuffer: GLuint;
	mAtomicBuffer: GLuint;
	mIndirectBuffer: GLuint;
	mOutputBuffers: GLuint[BufferNum];
	mSteps: Step[];


public:
	this(octTexture: GLuint, ref create: Create, kind: Kind)
	{
		store := getStore(ref create);
		b := new StepsBuilder(store);

		final switch (kind) with (Kind) {
		case Points0:
			name = "points-old";
			makePointsPipeline(b, false);
			break;
		case Points1:
			name = "points-new";
			makePointsPipeline(b, true);
			break;
		case CubePoint:
			name = "cubepoints";
			makeCubePointPipeline(b);
			break;
		case Raycube:
			name = "raycubes";
			makeRaycubePipeline(b);
			break;
		case Num: assert(false);
		}
		super(name);

		foreach (i, step; mSteps) {
			mTimeTrackers ~= new gfx.TimeTracker(step.name);
		}

		// Setup the texture.
		mOctTexture = octTexture;

		// Setup a VAO.
		mIndexBuffer = createIndexBuffer(662230u);
		glCreateVertexArrays(1, &mElementsVAO);
		glVertexArrayElementBuffer(mElementsVAO, mIndexBuffer);

		// Setup the dummy arrays VAO.
		glCreateVertexArrays(1, &mArrayVAO);

		// Create the storage for the atomic buffer.
		glCreateBuffers(1, &mAtomicBuffer);
		glNamedBufferStorage(mAtomicBuffer, 8 * 4, null, GL_DYNAMIC_STORAGE_BIT);

		// Indirect command buffer, used for both dispatch and drawing.
		glCreateBuffers(1, &mIndirectBuffer);
		glNamedBufferStorage(mIndirectBuffer, 4 * 16, null, GL_DYNAMIC_STORAGE_BIT);

		// Create the storage for the voxel lists.
		glCreateBuffers(cast(GLint)mOutputBuffers.length, mOutputBuffers.ptr);
		foreach (buf; mOutputBuffers) {
			glNamedBufferStorage(buf, 0x0800_0000, null, GL_DYNAMIC_STORAGE_BIT);
		}
	}

	fn makePointsPipeline(b: StepsBuilder, dub: bool)
	{
		buf0, buf3, buf5, buf6, buf7, buf9, buf11: u32;

		mSteps ~= b.makeInit(           out    buf0);
		mSteps ~= b.makeList1( buf0, 3, out    buf3);

		if (dub) {
			mSteps ~= b.makeList1( buf3, 2, out    buf5);
			mSteps ~= b.makeList1( buf5, 2, out    buf7);
			mSteps ~= b.makeList1( buf7, 2, out    buf9);
			mSteps ~= b.makeListDouble(buf9, out buf11);
		} else {
			mSteps ~= b.makeList1( buf3, 3, out    buf6);
			mSteps ~= b.makeList1( buf6, 3, out    buf9);
			mSteps ~= b.makeListDouble(buf9, out buf11);
		}
		mSteps ~= b.makePoints(buf11);
	}

	fn makeRayDoublePipeline(b: StepsBuilder, old: bool)
	{
		buf0, buf3, buf6, buf9: u32;

		mSteps ~= b.makeInit(           out    buf0);
		mSteps ~= b.makeList1( buf0, 3, out    buf3);
		mSteps ~= b.makeList1( buf3, 3, out    buf6);
		mSteps ~= b.makeList1( buf6, 3, out    buf9);
		if (old) {
			mSteps ~= new RayStep(b.s, buf9, 9, 2);
		} else {
			mSteps ~= b.makeRayDouble(buf9);
		}
	}

	fn makeCubePointPipeline(b: StepsBuilder)
	{
		buf0, buf3, buf6_1, buf6_2: u32;
		buf9_1, buf9_2, buf11_1, buf11_2: u32;
		buf8, buf10: u32;

		mSteps ~= b.makeInit(                         out    buf0);
		mSteps ~= b.makeList1(    buf0, 3,            out    buf3);
		mSteps ~= b.makeList2(    buf3, 3, 3.160798f, out  buf6_1, out  buf6_2);
		mSteps ~= b.makeList2(  buf6_1, 3, 1.580399f, out  buf9_1, out  buf9_2);
		mSteps ~= b.makeList2(  buf9_1, 2, 0.029376f, out buf11_1, out buf11_2);
		mSteps ~= b.makeCubes( buf11_1);
		mSteps ~= b.makePoints(buf11_2);

		mSteps ~= b.makeListDouble(buf9_2, out buf11_1);
		mSteps ~= b.makePoints(buf11_1);

		mSteps ~= b.makeList1(buf6_2, 2, out  buf8);
		mSteps ~= b.makeListDouble(buf8, out buf10);
		mSteps ~= b.makePoints(buf10);
	}

	fn makeRaycubePipeline(b: StepsBuilder)
	{
		// Setup the pipeline steps.
		mSteps ~= new InitStep(         0);
		mSteps ~= new ListStep(    b.s, 0, 1, 0, 0, 3, 0.0f);
		mSteps ~= new ListStep(    b.s, 1, 0, 0, 3, 2, 0.0f);
		mSteps ~= new ListStep(    b.s, 0, 1, 2, 5, 2, 0.1f);
		mSteps ~= new ListStep(    b.s, 1, 0, 0, 7, 3, 0.0f);
		mSteps ~= new RayStep(b.s, 0,      10, 1);
		mSteps ~= new ListStep(    b.s, 2, 0, 0, 7, 2, 0.0f);
		mSteps ~= new RayStep(b.s, 0,       9, 2);
	}

	override fn close()
	{
	}

	override fn doDraw(ref input: Draw)
	{
		frustum: math.Frustum;
		frustum.setFromUntransposedGL(ref input.cullMVP);
		height := cast(f64)input.targetHeight;
		fov := radians(cast(f64)input.fov);

		state: StepState;
		state.matrix.setToAndTranspose(ref input.camMVP);
		state.camPosition = input.cullPos;
		state.planes[0].setFrom(ref frustum.p[0]);
		state.planes[1].setFrom(ref frustum.p[1]);
		state.planes[2].setFrom(ref frustum.p[2]);
		state.planes[3].setFrom(ref frustum.p[3]);
		state.frame = input.frame;
		state.buffers = mOutputBuffers;
		state.atomicBuffer = mAtomicBuffer;
		state.commandBuffer = mIndirectBuffer;
		state.pointScale = cast(f32)
			(height / (2.0 * tan(fov / 2.0)));

/*
		dist: VoxelDistanceFinder;
		dist.setup(fov, input.targetHeight, input.targetWidth);
		io.error.writefln("#############");
		io.error.writefln("%s", dist.getDistance(10));
		io.error.writefln("%s", dist.getDistance(11));
		io.error.writefln("\n\n");
		io.error.flush();
*/
		glCheckError();
		glBindTextureUnit(0, mOctTexture);

		// Rest the atomic buffer.
		glClearNamedBufferData(mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Bind the special buffers.
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, mAtomicBuffer);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, mIndirectBuffer);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, mIndirectBuffer);

		// Bind the output/input buffers for the shaders.
		foreach (id, buf; mOutputBuffers) {
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cast(GLuint)id, buf);
		}
		// Bind the special indirect buffer as a output buffer as well.
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, BufferCommandId, mIndirectBuffer);

		// Bind the elements vao so we can access the indicies.
		glBindVertexArray(mElementsVAO);

		glCheckError();

		// Dispatch the entire pipeline.
		foreach (i, step; mSteps) {
			mTimeTrackers[i].start();
			step.run(ref state);
			mTimeTrackers[i].stop();
		}

		// Restore all state.
		glBindVertexArray(0);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, BufferCommandId, mIndirectBuffer);
		foreach (id, buf; mOutputBuffers) {
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cast(GLuint)id, 0);
		}

		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, 0);
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, 0);
		glCheckError();
	}

	fn debugCounter(src: u32) u32
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT);
		val: u32;
		offset := cast(GLintptr)(src * 4);
		glGetNamedBufferSubData(mAtomicBuffer, offset, 4, cast(void*)&val); 
		return val;
	}
}


/*!
 * Helper class to build a rendering pipeline.
 */
class StepsBuilder
{
public:
	s: ShaderStore;
	endLevelOfBuf: u32[BufferNum];
	tracker: BufferTracker;


public:
	this(s: ShaderStore)
	{
		this.s = s;
		tracker.setup(BufferNum);
		assert(this.s !is null);
	}

	fn makeInit(out dst: u32) InitStep
	{
		// Setup the pipeline steps.
		dst = tracker.get(); // Produce
		endLevelOfBuf[dst] = 0;
		return new InitStep(dst);
	}

	fn makeList1(src: u32, powerLevels: u32, out dst: u32) ListStep
	{
		powerStart := endLevelOfBuf[src];

		// Track used buffers and level they produce.
		dst = tracker.get(); // Produce
		tracker.free(src);   // Consume
		endLevelOfBuf[dst] = powerStart + powerLevels;
		return new ListStep(s, src, dst, 0, powerStart, powerLevels, 0.0f);
	}

	fn makeListDouble(src: u32, out dst: u32) ListDoubleStep
	{
		powerLevels := 2u;
		powerStart := endLevelOfBuf[src];

		// Track used buffers and level they produce.
		dst = tracker.get(); // Produce
		tracker.free(src);   // Consume
		endLevelOfBuf[dst] = powerStart + powerLevels;
		return new ListDoubleStep(s, src, dst, powerStart);
	}

	fn makeList2(src: u32, powerLevels: u32, distance: f32,
	             out dst1: u32, out dst2: u32) ListStep
	{
		powerStart := endLevelOfBuf[src];

		// Track used buffers and level they produce.
		dst1 = tracker.get(); // Produce
		dst2 = tracker.get(); // Produce
		tracker.free(src);    // Consume
		endLevelOfBuf[dst1] = powerStart + powerLevels;
		endLevelOfBuf[dst2] = powerStart + powerLevels;
		return new ListStep(s, src, dst1, dst2, powerStart, powerLevels, distance);
	}

	fn makeCubes(src: u32) CubeStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new CubeStep(s, src, powerStart);
	}

	fn makePoints(src: u32) PointsStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new PointsStep(s, src, powerStart);
	}

	fn makeRayDouble(src: u32) RayDoubleStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new RayDoubleStep(s, src, powerStart);
	}
}

/*!
 * Base class for all steps in a rendering pipeline.
 */
abstract class Step
{
public:
	name: string;


public:
	abstract fn run(ref state: StepState);
}

/*!
 * First step of any rendering pipeline.
 */
class InitStep : Step
{
public:
	dst: u32;


public:
	this(dst: u32)
	{
		this.name = "init";
		this.dst = dst;
	}

	override fn run(ref state: StepState)
	{
		frame := state.frame;
		one := 1;
		offset := cast(GLintptr)(dst * 4);

		// Make sure memory is all in place.
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);

		glClearNamedBufferData(state.commandBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glClearNamedBufferData(state.atomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(state.atomicBuffer, offset, 4, cast(void*)&one);
		glNamedBufferSubData(state.buffers[dst], 0, 16, cast(void*)[0, 0, frame, 0].ptr);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
	}
}

class ListStep : Step
{
public:
	dispatchShader: gfx.Shader;
	listShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, dst1: u32, dst2: u32,
	     powerStart: u32, powerLevels: u32, distance: f32)
	{
		this.name = "list";

		dispatchShader = s.makeComputeDispatchShader(src, BufferCommandId);
		listShader = s.makeListShader(src, dst1, dst2, powerStart, powerLevels, distance);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		listShader.bind();
		listShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("uMatrix", 1, false, ref state.matrix);
		listShader.float4("uPlanes".ptr, 4, &state.planes[0].a);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}
}

class ListDoubleStep : Step
{
public:
	dispatchShader: gfx.Shader;
	listShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, dst: u32, powerStart: u32)
	{
		this.name = "double";

		dispatchShader = s.makeComputeDispatchShader(src, BufferCommandId);
		listShader = s.makeListDoubleShader(src, dst, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);
//		// Test code
//		glCopyBufferSubData(
//			GL_ATOMIC_COUNTER_BUFFER,
//			GL_DISPATCH_INDIRECT_BUFFER,
//			src * 4, 0, 4);
//		glClearBufferSubData(GL_ATOMIC_COUNTER_BUFFER, GL_R32UI, src * 4, 4, GL_UNSIGNED_INT, GL_RED, null);

		listShader.bind();
		listShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("uMatrix", 1, false, ref state.matrix);
		listShader.float4("uPlanes".ptr, 4, &state.planes[0].a);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}
}

class CubeStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32)
	{
		this.name = "cubes";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeCubesShader(src, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

class RayStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32, powerLevels: u32)
	{
		this.name = "ray";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeRayShader(src, powerStart, powerLevels);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

class RayDoubleStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32)
	{
		this.name = "raydouble";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeRayDoubleShader(src, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

class PointsStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32)
	{
		this.name = "points";

		dispatchShader = s.makeArrayDispatchShader(src, BufferCommandId);
		drawShader = s.makePointsShader(src, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);
		drawShader.float1("uPointScale".ptr, state.pointScale);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glEnable(GL_PROGRAM_POINT_SIZE);
		glDrawArraysIndirect(GL_POINTS, null);
		glDisable(GL_PROGRAM_POINT_SIZE);
	}
}
