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
	mNew: GfxShader;
	mList: GfxShader;
	mCubes: GfxShader;
	mTrace: GfxShader;
	mIndirectDispatch: GfxShader;

	/// The number of levels that we trace.
	mTracePower: i32;
	mTracePowerStr: string;

	mOctTexture: GLuint;
	mFeedbackQuery: GLuint;

	mElementsVAO: GLuint;
	mArrayVAO: GLuint;

	mIndexBuffer: GLuint;
	mAtomicBuffer: GLuint;
	mIndirectBuffer: GLuint;
	mOutputBuffers: GLuint[10];


public:
	this(octTexture: GLuint)
	{
		useCubes = true;
		counters = new Counters("list", "trace");

		mTracePower = 2;
		mTracePowerStr = format("#define TRACE_POWER %s", mTracePower);

		// Create the storage for the atomic buffer.
		glCreateBuffers(1, &mAtomicBuffer);
		glNamedBufferStorage(mAtomicBuffer, 4, null, GL_DYNAMIC_STORAGE_BIT);

		glCreateBuffers(1, &mIndirectBuffer);
		glNamedBufferStorage(mIndirectBuffer, 4*16, null, GL_DYNAMIC_STORAGE_BIT);

		// Create the big output buffer.
		glCreateBuffers(10, mOutputBuffers.ptr);
		glNamedBufferStorage(mOutputBuffers[0], 8, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[1], 512*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[2], 512*512*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[3], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[4], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[5], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[6], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[7], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[8], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glNamedBufferStorage(mOutputBuffers[9], 512*512*8*4, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mOutputBuffers[0], GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glCheckError();

		// Setup a VAO.
		createIndexBuffer();
		glCreateVertexArrays(1, &mElementsVAO);
		glVertexArrayElementBuffer(mElementsVAO, mIndexBuffer);

		glCreateVertexArrays(1, &mArrayVAO);
		glVertexArrayVertexBuffer(mArrayVAO, 0, mOutputBuffers[3], 0, 8);
		glVertexArrayAttribIFormat(mArrayVAO, 0, 2, GL_UNSIGNED_INT, 0);
		glVertexArrayAttribBinding(mArrayVAO, 0, 0);
		glEnableVertexArrayAttrib(mArrayVAO, 0);

		mOctTexture = octTexture;
		glGenQueries(1, &mFeedbackQuery);

		vert, geom, frag, comp: string;

		comp = cast(string)read("res/power/shaders/mixed/list.comp.glsl");
		mList = makeShaderC("mixed.list", comp);

		comp = cast(string)read("res/power/shaders/mixed/indirect-dispatch.comp.glsl");
		mIndirectDispatch = makeShaderC("mixed.indirect-dispatch", comp);

		vert = cast(string)read("res/power/shaders/mixed/old.vert.glsl");
		frag = cast(string)read("res/power/shaders/mixed/old.frag.glsl");
		mTrace = makeShaderVGF("mixed.trace", vert, null, frag);

		vert = cast(string)read("res/power/shaders/mixed/tracer-geom.vert.glsl");
		geom = cast(string)read("res/power/shaders/mixed/tracer-geom.geom.glsl");
		frag = cast(string)read("res/power/shaders/mixed/tracer.frag.glsl");
		mNew = makeShaderVGF("mixed.tracer", vert, geom, frag);

		vert = cast(string)read("res/power/shaders/mixed/tracer-cubes.vert.glsl");
		frag = cast(string)read("res/power/shaders/mixed/tracer.frag.glsl");
		mCubes = makeShaderVGF("mixed.cubes", vert, null, frag);
	}

	void close()
	{
		if (counters !is null) {
			counters.close();
			counters = null;
		}
		if (mList !is null) {
			mList.breakApart();
			mList = null;
		}
		if (mTrace !is null) {
			mTrace.breakApart();
			mTrace = null;
		}
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		glCheckError();
		glBindTextureUnit(0, mOctTexture);

		counters.start(0);

		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, mAtomicBuffer);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, mIndirectBuffer);

		glNamedBufferSubData(mIndirectBuffer,   0, 4 * 3, cast(void*)[1, 1, 1].ptr);
		glNamedBufferSubData(mOutputBuffers[0], 4,     4, cast(void*)&frame);

		numSteps := 3u;
		foreach (i; 0 .. numSteps) {
			if (i != 0) {
				// Fill out the indirect buffer.
				mIndirectDispatch.bind();
				glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
				glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mIndirectBuffer);
				glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, 0);
				glDispatchCompute(1u, 1u, 1u);
			}

			mList.bind();
			glClearNamedBufferData(mAtomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, mOutputBuffers[i    ]);
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, mOutputBuffers[i + 1]);
			glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
			                GL_SHADER_STORAGE_BARRIER_BIT |
			                GL_COMMAND_BARRIER_BIT);
			glDispatchComputeIndirect(0);
			glCheckError();
		}

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, 0);
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, 0);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, 0);
		glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);

		counters.stop(0);

		counters.start(1);

		glCullFace(GL_FRONT);
		glEnable(GL_CULL_FACE);

		num := 0;
		glGetNamedBufferSubData(mAtomicBuffer, 0, 4, cast(void*)&num);
		buffer := mOutputBuffers[numSteps];
		if (useCubes) {
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, buffer);
			glBindVertexArray(mElementsVAO);
			setupStaticCubes(ref camPosition, ref mat);
			glDrawElements(GL_TRIANGLE_STRIP, num * 16, GL_UNSIGNED_INT, null);
		} else {
			glVertexArrayVertexBuffer(mArrayVAO, 0, buffer, 0, 8);
			glBindVertexArray(mArrayVAO);
			setupStaticTracer(ref camPosition, ref mat);
			glDrawArrays(GL_POINTS, 0, num);
		}

		glBindVertexArray(0);
		glDisable(GL_CULL_FACE);

		counters.stop(1);

		glUseProgram(0);
		glBindTextureUnit(0, 0);
		glCheckError();
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

		num := 662230u;
		data := [3, 2, 1, 0, 4, 2, 6, 3, 7, 1, 5, 4, 7, 6, 6, 3+8];
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

	fn setupStaticTrace(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mTrace.bind();
		mTrace.matrix4("matrix", 1, false, mat.ptr);
		mTrace.float3("cameraPos".ptr, camPosition.ptr);
	}

	fn setupStaticTracer(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mNew.bind();
		mNew.matrix4("matrix", 1, false, mat.ptr);
		mNew.float3("cameraPos".ptr, camPosition.ptr);
	}


	fn setupStaticCubes(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		mCubes.bind();
		mCubes.matrix4("matrix", 1, false, mat.ptr);
		mCubes.float3("cameraPos".ptr, camPosition.ptr);
	}

	fn makeShaderC(name: string, comp: string) GfxShader
	{
		comp = replaceShaderStrings(comp);
		return new GfxShader(name, comp);
	}

	fn makeShaderVGF(name: string, vert: string, geom: string, frag: string) GfxShader
	{
		vert = replaceShaderStrings(vert);
		geom = replaceShaderStrings(geom);
		frag = replaceShaderStrings(frag);
		return new GfxShader(name, vert, geom, frag);
	}

	fn replaceShaderStrings(shader: string) string
	{
		shader = replace(shader, "#define TRACE_POWER %%",   mTracePowerStr);
		return shader;
	}
}
