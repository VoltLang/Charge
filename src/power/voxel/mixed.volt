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


class Mixed
{
public:
	struct DrawState
	{
		matrix: math.Matrix4x4f;
		planes: math.Planef[4];
		camPosition: math.Point3f; pad: f32;
	}


public:
	frame: u32;
	useCubes: bool;
	counters: Counters;


protected:
	static class VoxelBuffer
	{
		bufferSource: u32;
		bufferDst1: u32;
		bufferDst2: u32;
		distance: f32;

		dispatchShader: GfxShader;
		drawShader: GfxShader;
	}

	static class DrawPass
	{
		bufferSource: u32;
		powerStart: u32;
		powerNum: u32;

		dispatchShader: GfxShader;
		drawShader: GfxShader;
	}

	static struct PassInfo
	{
		powerStart: u32;
		powerNum: u32;
		bufSrc: u32;
		bufDst1: u32;
		bufDst2: u32;
		distance: f32;
		draw: bool;
	}

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


public:
	this(octTexture: GLuint)
	{
		counters = new Counters("initial", "list1", "trace1", "list2", "trace2");

		{
			test: GLint;
			glGetIntegerv(GL_MAX_COMPUTE_ATOMIC_COUNTERS, &test);
			io.writefln("GL_MAX_COMPUTE_ATOMIC_COUNTERS: %s", test);
			glGetIntegerv(GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS, &test);
			io.writefln("GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS: %s", test);
			glGetIntegerv(GL_MAX_COMBINED_ATOMIC_COUNTERS, &test);
			io.writefln("GL_MAX_COMBINED_ATOMIC_COUNTERS: %s", test);
		}

		mXShift = 2;
		mYShift = 0;
		mZShift = 1;

		// Premake the shaders.
		makeComputeDispatchShader(0, 4);
		makeComputeDispatchShader(1, 4);
		makeComputeDispatchShader(2, 4);
		makeComputeDispatchShader(3, 4);
		makeElementsDispatchShader(0, 4);
		makeListShader(0, 1, 2, 0, 3, 0.0f);
		makeListShader(1, 0, 3, 3, 2, 0.0f);
		makeListShader(0, 1, 2, 5, 2, 0.1f);
		makeListShader(1, 0, 3, 7, 3, 0.0f);
		makeListShader(2, 0, 3, 7, 2, 0.0f);
		makeElementsShader(0, 10, 1);
		makeElementsShader(0, 9, 2);

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
		mOutputBuffers = new GLuint[](4);
		glCreateBuffers(cast(GLint)mOutputBuffers.length, mOutputBuffers.ptr);
		foreach (i, ref buf; mOutputBuffers) {
			glNamedBufferStorage(mOutputBuffers[i], 0x200_0000, null, GL_DYNAMIC_STORAGE_BIT);
		}
	}

	void close()
	{
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4d)
	{
		frustum: math.Frustum;
		frustum.setFromGL(ref mat);
		state: DrawState;
		state.matrix.setFrom(ref mat);
		state.camPosition = camPosition;
		state.planes[0].setFrom(ref frustum.p[0]);
		state.planes[1].setFrom(ref frustum.p[1]);
		state.planes[2].setFrom(ref frustum.p[2]);
		state.planes[3].setFrom(ref frustum.p[3]);

		glCheckError();
		glBindTextureUnit(0, mOctTexture);

		glClearNamedBufferData(mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, mAtomicBuffer);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, mIndirectBuffer);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, mIndirectBuffer);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mOutputBuffers[0]);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, mOutputBuffers[1]);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, mOutputBuffers[2]);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, mOutputBuffers[3]);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, mIndirectBuffer);

		glBindVertexArray(mElementsVAO);

		glCheckError();

		counters.start(0);
		initConfig(dst: 0);
		runListShader(ref state, 0, 1, 2, 0, 3, 0.0f);
		runListShader(ref state, 1, 0, 3, 3, 2, 0.0f);
		runListShader(ref state, 0, 1, 2, 5, 2, 0.1f);
		counters.stop(0);

		counters.start(1);
		runListShader(ref state, 1, 0, 3, 7, 3, 0.0f);
		counters.stop(1);

		counters.start(2);
		runElementShader(ref state, 0, 10, 1);
		counters.stop(2);


		counters.start(3);
		runListShader(ref state, 2, 0, 3, 7, 2, 0.0f);
		counters.stop(3);

		counters.start(4);
		runElementShader(ref state, 0, 9, 2);
		counters.stop(4);


		glBindVertexArray(0);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);

		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, 0);
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, 0);
		glCheckError();
	}

	fn initConfig(dst: u32)
	{
		one := 1;
		offset := cast(GLintptr)(dst * 4);
		glClearNamedBufferData(mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(mAtomicBuffer, offset, 4, cast(void*)&one);
		glNamedBufferSubData(mOutputBuffers[dst], 0, 8, cast(void*)[0, frame].ptr);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT);
	}

	fn runComputeDispatch(src: u32)
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		s := makeComputeDispatchShader(src, 4);
		s.bind();
		glDispatchCompute(1u, 1u, 1u);
	}

	fn runListShader(ref state: DrawState, src: u32, dst1: u32, dst2: u32,
	                 powerStart: u32, powerLevels: u32, dist: f32)
	{
		// Setup the indirect buffer first.
		runComputeDispatch(src);

		s := makeListShader(src, dst1, dst2, powerStart, powerLevels, dist);
		s.bind();
		s.float3("cameraPos".ptr, state.camPosition.ptr);
		s.matrix4("matrix", 1, false, ref state.matrix);
		s.float4("planes".ptr, 4, &state.planes[0].a);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT |
		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}

	fn runElementsDispatch(src: u32)
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		s := makeElementsDispatchShader(src, 4);
		s.bind();
		glDispatchCompute(1u, 1u, 1u);
	}

	fn runElementShader(ref state: DrawState, src: u32,
	                    powerStart: u32, powerLevels: u32)
	{
		runElementsDispatch(src);

		s := makeElementsShader(src, powerStart, powerLevels);
		s.bind();
		s.float3("cameraPos".ptr, state.camPosition.ptr);
		s.matrix4("matrix", 1, false, ref state.matrix);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT |
		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
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
		//data := [3, 2, 1, 0, 4, 2, 6, 3, 7, 1, 5, 4, 7, 6, 6, 3+8];
		  data := [4, 5, 6, 7, 2, 3, 3, 7, 1, 5, 5, 4+8];
		length := cast(GLsizeiptr)(data.length * num * 4);

		glCreateBuffers(1, &mIndexBuffer);
		glNamedBufferData(mIndexBuffer, length, null, GL_STATIC_DRAW);
		ptr := cast(i32*)glMapNamedBuffer(mIndexBuffer, GL_WRITE_ONLY);

		foreach (i; 0 .. num) {
			foreach (d; data) {
				*ptr = d + cast(i32)i * 8;
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
}
