// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.mixed;

import watt.text.string;
import watt.text.format;
import watt.io.file;
import io = watt.io;

import charge.gfx;
import charge.sys.resource;

import math = charge.math;

import power.util.counters;
import power.voxel.dag;
import power.voxel.boxel;
import power.voxel.instance;


fn calcAlign(pos: i32, level: i32) i32
{
	shift := level + 1;
	size := 1 << level;
	return ((pos + size) >> shift) << shift;
}

fn getAlignedPosition(ref camPosition: math.Point3f,
                      out position: math.Vector3f,
                      scaleFactor: f32)
{
	position = math.Vector3f.opCall(camPosition);
	position.scale(scaleFactor);
	position.floor();

	vec := math.Vector3f.opCall(
		cast(f32)calcAlign(cast(i32)position.x, 0),
		cast(f32)calcAlign(cast(i32)position.y, 0),
		cast(f32)calcAlign(cast(i32)position.z, 0));
}
	
fn calcNumMorton(dim: i32) i32
{
	return dim * dim * dim;
}




class Mixed
{
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
		counters = new Counters("list   0 -  9", "trace 9 - 11",
		                        "list   6 -  8", "trace 8 - 11",
		                        "list   3 -  8", "trace 8 - 10",
		                        "list   5 -  7", "trace 7 - 10");

		{
			test: GLint;
			glGetIntegerv(GL_MAX_COMPUTE_ATOMIC_COUNTERS, &test);
			io.writefln("GL_MAX_COMPUTE_ATOMIC_COUNTERS: %s", test);
			glGetIntegerv(GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS, &test);
			io.writefln("GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS: %s", test);
			glGetIntegerv(GL_MAX_COMBINED_ATOMIC_COUNTERS, &test);
			io.writefln("GL_MAX_COMBINED_ATOMIC_COUNTERS: %s", test);
		}

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

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		s: GfxShader;

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
		initConfig(dst: 1);
		runListShader(ref camPosition, ref mat, 1, 0, 2, 0, 3, 0.5f);
		runListShader(ref camPosition, ref mat, 0, 3, 1, 3, 3, 0.3f);
		runListShader(ref camPosition, ref mat, 3, 0, 1, 6, 3, 0.0f);
		counters.stop(0);

		counters.start(1);
		runElementShader(ref camPosition, ref mat, 0, 9, 2);
		counters.stop(1);

		counters.start(2);
		runListShader(ref camPosition, ref mat, 1, 0, 1, 6, 2, 0.0f);
		counters.stop(2);

		counters.start(3);
		runElementShader(ref camPosition, ref mat, 0, 8, 3);
		counters.stop(3);

		counters.start(4);
		runListShader(ref camPosition, ref mat, 2, 1, 3, 3, 2, 0.6f);
		runListShader(ref camPosition, ref mat, 1, 0, 1, 5, 3, 0.0f);
		counters.stop(4);

		counters.start(5);
		runElementShader(ref camPosition, ref mat, 0, 8, 2);
		counters.stop(5);

		counters.start(6);
		runListShader(ref camPosition, ref mat, 3, 0, 1, 5, 2, 0.0f);
		counters.stop(6);

		counters.start(7);
		runElementShader(ref camPosition, ref mat, 0, 7, 2);
		counters.stop(7);

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
		zero := 0;
		offset := cast(GLintptr)(src * 4);
		glNamedBufferSubData(mAtomicBuffer, offset, 4, cast(void*)&zero);
	}

	fn runListShader(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f,
	                  src: u32, dst1: u32, dst2: u32,
	                  powerStart: u32, powerLevels: u32, dist: f32)
	{
		// Setup the indirect buffer first.
		runComputeDispatch(src);

		s := makeListShader(src, dst1, dst2, powerStart, powerLevels, dist);
		s.bind();
		s.float3("cameraPos".ptr, camPosition.ptr);
		s.matrix4("matrix", 1, false, mat.ptr);
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
		zero := 0;
		offset := cast(GLintptr)(src * 4);
		glNamedBufferSubData(mAtomicBuffer, offset, 4, cast(void*)&zero);
	}

	fn runElementShader(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f,
	                    src: u32, powerStart: u32, powerLevels: u32)
	{
		runElementsDispatch(src);

		s := makeDrawElementsShader(src, powerStart, powerLevels);
		s.bind();
		s.float3("cameraPos".ptr, camPosition.ptr);
		s.matrix4("matrix", 1, false, mat.ptr);
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT |
		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}

	fn debugCounter(str: string, src: u32)
	{
		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
		                GL_SHADER_STORAGE_BARRIER_BIT);
		val: u32;
		offset := cast(GLintptr)(src * 4);
		glGetNamedBufferSubData(mAtomicBuffer, offset, 4, cast(void*)&val); 
		io.writefln("%s: %s", str, val); 
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

		comp := cast(string)read("res/power/shaders/mixed/indirect-dispatch.comp.glsl");
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

		comp := cast(string)read("res/power/shaders/mixed/indirect-elements.comp.glsl");
		comp = replace(comp, "#define INDIRECT_SRC %%", indSrcStr);
		comp = replace(comp, "#define INDIRECT_DST %%", indDstStr);

		s := new GfxShader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeListShader(src: u32, dst1: u32, dst2: u32,
	                  powerStart: u32, powerLevels: u32, dist: f32) GfxShader
	{
		name := format("mixed.list (src: %s, dst1: %s, dst2: %s, powerStart: %s, powerLevels: %s)",
			src, dst1, dst2, powerStart, powerLevels);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)read("res/power/shaders/mixed/list.comp.glsl");
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

	fn makeDrawElementsShader(src: u32, powerStart: u32, powerLevels: u32) GfxShader
	{
		name := format("mixed.tracer (src: %s, start: %s, levels: %s)",
			src, powerStart, powerLevels);
		if (s := name in mShaderStore) {
			return *s;
		}

		voxelSrcStr := format("#define VOXEL_SRC %s", src);
		powerStartStr := format("#define POWER_START %s", powerStart);
		powerLevelsStr := format("#define POWER_LEVELS %s", powerLevels);

		vert := cast(string)read("res/power/shaders/mixed/tracer-cubes.vert.glsl");
		vert = replace(vert, "#define VOXEL_SRC %%", voxelSrcStr);
		vert = replace(vert, "#define POWER_START %%", powerStartStr);
		vert = replace(vert, "#define POWER_LEVELS %%", powerLevelsStr);
		frag := cast(string)read("res/power/shaders/mixed/tracer.frag.glsl");
		frag = replace(frag, "#define VOXEL_SRC %%", voxelSrcStr);
		frag = replace(frag, "#define POWER_START %%", powerStartStr);
		frag = replace(frag, "#define POWER_LEVELS %%", powerLevelsStr);

		s := new GfxShader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}
}
