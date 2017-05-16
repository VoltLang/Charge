// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.mixed;

import watt.text.string;
import watt.text.format;
import io = watt.io;

import charge.gfx;
import charge.sys.resource;

import math = charge.math;

import power.util.counters;
import power.voxel.dag;
import power.voxel.boxel;
import power.voxel.instance;
static import voxel.gfx.input;


class Mixed
{
public:
	alias DrawInput = voxel.gfx.input.Draw;
	alias CreateInput = voxel.gfx.input.Create;

	struct DrawState
	{
		matrix: math.Matrix4x4f;
		planes: math.Planef[4];
		camPosition: math.Point3f; frame: u32;
	}


public:
	counters: Counters;


protected:


	mXShift, mYShift, mZShift: u32;
	mShaderStore: GfxShader[string];

	mOctTexture: GLuint;
	mFeedbackQuery: GLuint;

	mElementsVAO: GLuint;
	mArrayVAO: GLuint;

	mIndexBuffer: GLuint;
	mAtomicBuffer: GLuint;
	mIndirectBuffer: GLuint;
	mOutputBuffers: GLuint[];
	mSteps: Step[];


public:
	this(octTexture: GLuint, ref create: CreateInput)
	{

/*
		{
			test: GLint;
			glGetIntegerv(GL_MAX_COMPUTE_ATOMIC_COUNTERS, &test);
			io.writefln("GL_MAX_COMPUTE_ATOMIC_COUNTERS: %s", test);
			glGetIntegerv(GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS, &test);
			io.writefln("GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS: %s", test);
			glGetIntegerv(GL_MAX_COMBINED_ATOMIC_COUNTERS, &test);
			io.writefln("GL_MAX_COMBINED_ATOMIC_COUNTERS: %s", test);
		}

		{
			test: math.Matrix4x4d;
			test = input.camMVP;
			test.inverse();
			p1 := math.Point3f.opCall(0.f, 0.f,  1.f);
			p2 := math.Point3f.opCall(0.f, 0.f, -1.f);
			p1 = test / p1;
			p2 = test / p2;
			io.writefln("far  %s", p1.toString());
			io.writefln("near %s", p2.toString());
			io.writefln("plane near (%s %s %s) %s", frustum.p[5].a, frustum.p[5].b, frustum.p[5].c, frustum.p[5].d);
			io.writefln("plane far  (%s %s %s) %s", frustum.p[4].a, frustum.p[4].b, frustum.p[4].c, frustum.p[4].d);
			io.output.flush();
		}
*/
	
		mXShift = create.xShift;
		mYShift = create.yShift;
		mZShift = create.zShift;

		// Premake the shaders.
		makeComputeDispatchShader(0, BufferCommandId);
		makeComputeDispatchShader(1, BufferCommandId);
		makeComputeDispatchShader(2, BufferCommandId);
		makeComputeDispatchShader(3, BufferCommandId);
		makeElementsDispatchShader(0, BufferCommandId);
		makeArrayDispatchShader(0, BufferCommandId);

		// Setup the pipeline steps.
		mSteps ~= newInitStep(p:     this,         dst:  0);
		mSteps ~= newList1Step(p:    this, src: 0, dst:  1, powerStart:  0, powerLevels: 3);
		mSteps ~= newList1Step(p:    this, src: 1, dst:  0, powerStart:  3, powerLevels: 2);
		mSteps ~= newList2Step(p:    this, src: 0, dst1: 1, powerStart:  5, powerLevels: 2, dst2: 2, distance: 0.1f);
		mSteps ~= newList1Step(p:    this, src: 1, dst:  0, powerStart:  7, powerLevels: 3);
		mSteps ~= newElementsStep(p: this, src: 0,          powerStart: 10, powerLevels: 1);
		mSteps ~= newList1Step(p:    this, src: 2, dst:  0, powerStart:  7, powerLevels: 2);
		mSteps ~= newElementsStep(p: this, src: 0,          powerStart:  9, powerLevels: 2);
		names: string[];
		foreach (i, step; mSteps) {
			names ~= step.name;
		}
		counters = new Counters(names);

		// Setup the texture.
		mOctTexture = octTexture;

		// Setup a VAO.
		createIndexBuffer();
		glCreateVertexArrays(1, &mElementsVAO);
		glVertexArrayElementBuffer(mElementsVAO, mIndexBuffer);

		glCreateVertexArrays(1, &mArrayVAO);
		glVertexArrayVertexBuffer(mArrayVAO, 0, 0, 0, 8);
		glVertexArrayAttribIFormat(mArrayVAO, 0, 2, GL_UNSIGNED_INT, 0);
		glVertexArrayAttribBinding(mArrayVAO, 0, 0);
		glEnableVertexArrayAttrib(mArrayVAO, 0);

		// Create the storage for the atomic buffer.
		glCreateBuffers(1, &mAtomicBuffer);
		glNamedBufferStorage(mAtomicBuffer, 8 * 4, null, GL_DYNAMIC_STORAGE_BIT);

		// Indirect command buffer, used for both dispatch and drawing.
		glCreateBuffers(1, &mIndirectBuffer);
		glNamedBufferStorage(mIndirectBuffer, 4 * 16, null, GL_DYNAMIC_STORAGE_BIT);

		// Create the storage for the voxel lists.
		mOutputBuffers = new GLuint[](BufferNum);
		glCreateBuffers(cast(GLint)mOutputBuffers.length, mOutputBuffers.ptr);
		foreach (i, ref buf; mOutputBuffers) {
			glNamedBufferStorage(mOutputBuffers[i], 0x800_0000, null, GL_DYNAMIC_STORAGE_BIT);
		}
	}

	void close()
	{
	}

	fn draw(ref input: DrawInput)
	{
		frustum: math.Frustum;
		frustum.setFromUntransposedGL(ref input.cullMVP);

		state: DrawState;
		state.matrix.setToAndTranspose(ref input.camMVP);
		state.camPosition = input.cullPos;
		state.planes[0].setFrom(ref frustum.p[0]);
		state.planes[1].setFrom(ref frustum.p[1]);
		state.planes[2].setFrom(ref frustum.p[2]);
		state.planes[3].setFrom(ref frustum.p[3]);
		state.frame = input.frame;


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
			counters.start(i);
			step.run(ref state);
			counters.stop(i);
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


private:
	fn createIndexBuffer()
	{
		/*
		 * bitRakes' tri-strip cube, modified to fit OpenGL.
		 *
		 * Its still a bit DXy so backsides of triangles are out.
		 *
		 * 6-------2-------3-------7
		 * |  E __/|\__ A  |  H __/|   
		 * | __/   |   \__ | __/   |   
		 * |/   D  |  B   \|/   I  |
		 * 4-------0-------1-------5
		 *         |  C __/|
		 *         | __/   |  Cube = 8 vertices
		 *         |/   J  |  =================
		 *         4-------5  Single Strip: 3 2 1 0 4 2 6 3 7 1 5 4 7 6
		 *         |\__ K  |  12 triangles:     A B C D E F G H I J K L
		 *         |   \__ |
		 *         |  L   \|         Left  D+E
		 *         6-------7        Right  H+I
		 *         |\__ G  |         Back  K+L
		 *         |   \__ |        Front  A+B
		 *         |  F   \|          Top  F+G
		 *         2-------3       Bottom  C+J
		 *
		 */

		num := 662230u*2;
		//data: u32[] = [3, 2, 1, 0, 4, 2, 6, 3, 7, 1, 5, 4, 7, 6, 6, 3+8];
		  data: u32[] = [4, 5, 6, 7, 2, 3, 3, 7, 1, 5, 5, 4+8];
		length := cast(GLsizeiptr)(data.length * num * 4);

		glCreateBuffers(1, &mIndexBuffer);
		glNamedBufferData(mIndexBuffer, length, null, GL_STATIC_DRAW);
		ptr := cast(u32*)glMapNamedBuffer(mIndexBuffer, GL_WRITE_ONLY);

		foreach (i; 0 .. num) {
			foreach (d; data) {
				*ptr = d + i * 8;
				ptr++;
			}
		}

		glUnmapNamedBuffer(mIndexBuffer);
	}

	fn makeComputeDispatchShader(src: u32, dst: u32) GfxShader
	{
		name := format("mixed.comp-dispatch (src: %s, dst: %s)", src, dst);
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
		name := format("mixed.elements-dispatch (src: %s, dst: %s)", src, dst);
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
		name := format("mixed.array-dispatch (src: %s, dst: %s)", src, dst);
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
		name := format("mixed.list (src: %s, dst1: %s, dst2: %s, powerStart: %s, powerLevels: %s, dist: %s)",
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

	fn makeElementsShader(src: u32, powerStart: u32, powerLevels: u32) GfxShader
	{
		name := format("mixed.tracer (src: %s, start: %s, levels: %s)",
			src, powerStart, powerLevels);
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
		name := format("mixed.point (src: %s, start: %s)",
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


/*
 *
 * Steps code.
 *
 */

enum BufferNum = 4;
enum GLuint BufferCommandId = BufferNum; // Buffer ids start at zero.

fn newInitStep(p: Mixed = null, dst: u32) InitStep
{
	return new InitStep(p, dst);
}

fn newList1Step(p: Mixed, src: u32, dst: u32,
                powerStart: u32, powerLevels: u32) ListStep
{
	return new ListStep(p, src, dst, 0, powerStart, powerLevels, 0.0f);
}
fn newList2Step(p: Mixed, src: u32, dst1: u32, dst2: u32,
                powerStart: u32, powerLevels: u32, distance: f32) ListStep
{
	return new ListStep(p, src, dst1, dst2, powerStart, powerLevels, distance);
}

fn newElementsStep(p: Mixed, src: u32, powerStart: u32, powerLevels: u32) ElementsStep
{
	return new ElementsStep(p, src, powerStart, powerLevels);
}

fn newPointsStep(p: Mixed, src: u32, powerStart: u32) PointsStep
{
	return new PointsStep(p, src, powerStart);
}

fn newCubesStep(p: Mixed, src: u32, powerStart: u32) ElementsStep
{
	return new ElementsStep(p, src, powerStart, 0);
}


static abstract class Step
{
	name: string;
	abstract fn run(ref state: Mixed.DrawState);
}

class InitStep : Step
{
public:
	p: Mixed;
	dst: u32;


public:
	this(p: Mixed, dst: u32)
	{
		this.name = "init";
		this.p = p;
		this.dst = dst;
	}

	override fn run(ref state: Mixed.DrawState)
	{
		frame := state.frame;
		one := 1;
		offset := cast(GLintptr)(dst * 4);

		glClearNamedBufferData(p.mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(p.mAtomicBuffer, offset, 4, cast(void*)&one);
		glNamedBufferSubData(p.mOutputBuffers[dst], 0, 16, cast(void*)[0, 0, frame, 0].ptr);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT);
	}
}

static class ListStep : Step
{
public:
	dispatchShader: GfxShader;
	listShader: GfxShader;


public:
	this(p: Mixed, src: u32, dst1: u32, dst2: u32,
	     powerStart: u32, powerLevels: u32, distance: f32)
	{
		this.name = "list";

		dispatchShader =  p.makeComputeDispatchShader(src, BufferCommandId);
		listShader = p.makeListShader(src, dst1, dst2, powerStart, powerLevels, distance);
	}

	override fn run(ref state: Mixed.DrawState)
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		listShader.bind();
		listShader.float3("cameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("matrix", 1, false, ref state.matrix);
		listShader.float4("planes".ptr, 4, &state.planes[0].a);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT |
		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}
}

static class ElementsStep : Step
{
public:
	dispatchShader: GfxShader;
	drawShader: GfxShader;


public:
	this(p: Mixed, src: u32, powerStart: u32, powerLevels: u32)
	{
		this.name = powerLevels == 0 ? "cubes" : "raycube";

		dispatchShader =  p.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = p.makeElementsShader(src, powerStart, powerLevels);
	}

	override fn run(ref state: Mixed.DrawState)
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("cameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("matrix", 1, false, ref state.matrix);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT |
		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

static class PointsStep : Step
{
public:
	dispatchShader: GfxShader;
	drawShader: GfxShader;


public:
	this(p: Mixed, src: u32, powerStart: u32)
	{
		this.name = "points";

		dispatchShader =  p.makeArrayDispatchShader(src, BufferCommandId);
		drawShader = p.makePointsShader(src, powerStart);
	}

	override fn run(ref state: Mixed.DrawState)
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("cameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("matrix", 1, false, ref state.matrix);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT |
		                GL_COMMAND_BARRIER_BIT);
		glEnable(GL_PROGRAM_POINT_SIZE);
		glDrawArraysIndirect(GL_POINTS, null);
		glDisable(GL_PROGRAM_POINT_SIZE);
	}
}
