// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.shaders;

import watt.text.string;
import watt.text.format;
import io = watt.io;

import charge.gfx;
import charge.sys.resource;

import math = charge.math;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.shaders;
import voxel.svo.pipeline;


/**
 * The state that is passed to each step when we are running the pipeline.
 */
struct StepState
{
	matrix: math.Matrix4x4f;
	planes: math.Planef[4];
	camPosition: math.Point3f; frame: u32;
	pointScale: f32;

	// State for helpers not shaders.
	buffers: GLuint[BufferNum];
	atomicBuffer: GLuint;
	commandBuffer: GLuint;
}

private global voxelShaderStoreStore: ShaderStore[const(u32)[]];

fn getStore(xShift: u32, yShift: u32, zShift: u32) ShaderStore
{
	key := [xShift, yShift, zShift];
	s := key in voxelShaderStoreStore;
	if (s !is null) {
		return *s;
	}

	store := new ShaderStore(xShift, yShift, zShift);
	voxelShaderStoreStore[key] = store;
	return store;
}

/**
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
		return new ListDoubleStep(s, src, dst, 0, powerStart);
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

	fn makeCubes(src: u32) ElementsStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new ElementsStep(s, src, powerStart, 0);
	}

	fn makePoints(src: u32) PointsStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new PointsStep(s, src, powerStart);
	}
}

/**
 * Base class for all steps in a rendering pipeline.
 */
abstract class Step
{
public:
	name: string;


public:
	abstract fn run(ref state: StepState);
}

/**
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
	dispatchShader: GfxShader;
	listShader: GfxShader;


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
		listShader.float3("cameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("matrix", 1, false, ref state.matrix);
		listShader.float4("planes".ptr, 4, &state.planes[0].a);

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
	dispatchShader: GfxShader;
	listShader: GfxShader;


public:
	this(s: ShaderStore, src: u32, dst1: u32, dst2: u32, powerStart: u32)
	{
		this.name = "list";

		dispatchShader = s.makeComputeDispatchShader(src, BufferCommandId);
		listShader = s.makeListDoubleShader(src, dst1, dst2, powerStart);
	}

	override fn run(ref state: StepState)
	{

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		listShader.bind();
		listShader.float3("cameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("matrix", 1, false, ref state.matrix);
		listShader.float4("planes".ptr, 4, &state.planes[0].a);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}
}

class ElementsStep : Step
{
public:
	dispatchShader: GfxShader;
	drawShader: GfxShader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32, powerLevels: u32)
	{
		this.name = powerLevels == 0 ? "cubes" : "raycube";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeElementsShader(src, powerStart, powerLevels);
	}

	override fn run(ref state: StepState)
	{

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("cameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("matrix", 1, false, ref state.matrix);

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
	dispatchShader: GfxShader;
	drawShader: GfxShader;


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
		drawShader.float3("cameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("matrix", 1, false, ref state.matrix);
		drawShader.float1("pointScale".ptr, state.pointScale);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glEnable(GL_PROGRAM_POINT_SIZE);
		glDrawArraysIndirect(GL_POINTS, null);
		glDisable(GL_PROGRAM_POINT_SIZE);
	}
}

/**
 * Cache shaders so they can be resude between different passes and models.
 */
class ShaderStore
{
protected:
	mXShift, mYShift, mZShift: u32;
	mShaderStore: GfxShader[string];


public:
	this(xShift: u32, yShift: u32, zShift: u32)
	{
		this.mXShift = xShift;
		this.mYShift = yShift;
		this.mZShift = zShift;

		makeComputeDispatchShader(0, BufferCommandId);
		makeComputeDispatchShader(1, BufferCommandId);
		makeComputeDispatchShader(2, BufferCommandId);
		makeComputeDispatchShader(3, BufferCommandId);
		makeElementsDispatchShader(0, BufferCommandId);
		makeArrayDispatchShader(0, BufferCommandId);
	}

	fn makeComputeDispatchShader(src: u32, dst: u32) GfxShader
	{
		name := format("svo.comp-dispatch (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		indSrcStr := format("#define INDIRECT_SRC %s", src);
		indDstStr := format("#define INDIRECT_DST %s", dst);

		comp := cast(string)import("power/shaders/indirect-dispatch.comp.glsl");
		comp = replace(comp, "#define INDIRECT_SRC %%", indSrcStr);
		comp = replace(comp, "#define INDIRECT_DST %%", indDstStr);

		s := new GfxShader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeElementsDispatchShader(src: u32, dst: u32) GfxShader
	{
		name := format("svo.elements-dispatch (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		indSrcStr := format("#define INDIRECT_SRC %s", src);
		indDstStr := format("#define INDIRECT_DST %s", dst);

		comp := cast(string)import("power/shaders/indirect-elements.comp.glsl");
		comp = replace(comp, "#define INDIRECT_SRC %%", indSrcStr);
		comp = replace(comp, "#define INDIRECT_DST %%", indDstStr);

		s := new GfxShader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeArrayDispatchShader(src: u32, dst: u32) GfxShader
	{
		name := format("svo.array-dispatch (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		indSrcStr := format("#define INDIRECT_SRC %s", src);
		indDstStr := format("#define INDIRECT_DST %s", dst);

		comp := cast(string)import("power/shaders/indirect-array.comp.glsl");
		comp = replace(comp, "#define INDIRECT_SRC %%", indSrcStr);
		comp = replace(comp, "#define INDIRECT_DST %%", indDstStr);

		s := new GfxShader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeListShader(src: u32, dst1: u32, dst2: u32,
	                  powerStart: u32, powerLevels: u32, dist: f32) GfxShader
	{
		name := format("svo.list (src: %s, dst1: %s, dst2: %s, powerStart: %s, powerLevels: %s, dist: %s)",
			src, dst1, dst2, powerStart, powerLevels, dist);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("power/shaders/list.comp.glsl");
		comp = replace(comp, "%X_SHIFT%", format("%s", mXShift));
		comp = replace(comp, "%Y_SHIFT%", format("%s", mYShift));
		comp = replace(comp, "%Z_SHIFT%", format("%s", mZShift));
		comp = replace(comp, "%VOXEL_SRC%", format("%s", src));
		comp = replace(comp, "%VOXEL_DST1%", format("%s", dst1));
		comp = replace(comp, "%VOXEL_DST2%", format("%s", dst2));
		comp = replace(comp, "%POWER_START%", format("%s", powerStart));
		comp = replace(comp, "%POWER_LEVELS%", format("%s", powerLevels));
		comp = replace(comp, "%POWER_DISTANCE%", format("%s", dist));
		if (dist > 0.0001) {
			comp = replace(comp, "#undef LIST_DO_TAG", "#define LIST_DO_TAG");
		}
		s := new GfxShader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeListDoubleShader(src: u32, dst1: u32, dst2: u32, powerStart: u32) GfxShader
	{
		name := format("svo.list-double (src: %s, dst1: %s, dst2: %s, powerStart: %s)",
			src, dst1, dst2, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/list-double.comp.glsl");
		comp = replace(comp, "%X_SHIFT%", format("%s", mXShift));
		comp = replace(comp, "%Y_SHIFT%", format("%s", mYShift));
		comp = replace(comp, "%Z_SHIFT%", format("%s", mZShift));
		comp = replace(comp, "%VOXEL_SRC%", format("%s", src));
		comp = replace(comp, "%VOXEL_DST1%", format("%s", dst1));
		comp = replace(comp, "%VOXEL_DST2%", format("%s", dst2));
		comp = replace(comp, "%POWER_START%", format("%s", powerStart));
		s := new GfxShader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeElementsShader(src: u32, powerStart: u32, powerLevels: u32) GfxShader
	{
		suffix := powerLevels == 0 ? "cubes" : "tracer";
		name := format("svo.%s (src: %s, start: %s, levels: %s)",
			suffix, src, powerStart, powerLevels);
		if (s := name in mShaderStore) {
			return *s;
		}

		voxelSrcStr := format("#define VOXEL_SRC %s", src);
		powerStartStr := format("#define POWER_START %s", powerStart);
		powerLevelsStr := format("#define POWER_LEVELS %s", powerLevels);

		vert := cast(string)import("power/shaders/tracer.vert.glsl");
		vert = replace(vert, "%X_SHIFT%", format("%s", mXShift));
		vert = replace(vert, "%Y_SHIFT%", format("%s", mYShift));
		vert = replace(vert, "%Z_SHIFT%", format("%s", mZShift));
		vert = replace(vert, "#define VOXEL_SRC %%", voxelSrcStr);
		vert = replace(vert, "#define POWER_START %%", powerStartStr);
		vert = replace(vert, "#define POWER_LEVELS %%", powerLevelsStr);
		frag := cast(string)import("power/shaders/tracer.frag.glsl");
		frag = replace(frag, "%X_SHIFT%", format("%s", mXShift));
		frag = replace(frag, "%Y_SHIFT%", format("%s", mYShift));
		frag = replace(frag, "%Z_SHIFT%", format("%s", mZShift));
		frag = replace(frag, "#define VOXEL_SRC %%", voxelSrcStr);
		frag = replace(frag, "#define POWER_START %%", powerStartStr);
		frag = replace(frag, "#define POWER_LEVELS %%", powerLevelsStr);

		s := new GfxShader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}

	fn makePointsShader(src: u32, powerStart: u32) GfxShader
	{
		name := format("svo.points (src: %s, start: %s)",
			src, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		voxelSrcStr := format("#define VOXEL_SRC %s", src);
		powerStartStr := format("#define POWER_START %s", powerStart);

		vert := cast(string)import("power/shaders/points.vert.glsl");
		vert = replace(vert, "%X_SHIFT%", format("%s", mXShift));
		vert = replace(vert, "%Y_SHIFT%", format("%s", mYShift));
		vert = replace(vert, "%Z_SHIFT%", format("%s", mZShift));
		vert = replace(vert, "#define VOXEL_SRC %%", voxelSrcStr);
		vert = replace(vert, "#define POWER_START %%", powerStartStr);
		frag := cast(string)import("power/shaders/points.frag.glsl");
		frag = replace(frag, "%X_SHIFT%", format("%s", mXShift));
		frag = replace(frag, "%Y_SHIFT%", format("%s", mYShift));
		frag = replace(frag, "%Z_SHIFT%", format("%s", mZShift));
		frag = replace(frag, "#define VOXEL_SRC %%", voxelSrcStr);
		frag = replace(frag, "#define POWER_START %%", powerStartStr);

		s := new GfxShader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}
}

