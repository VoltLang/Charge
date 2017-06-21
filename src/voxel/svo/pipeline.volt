// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.pipeline;

import watt.text.string;
import watt.text.format;
import watt.math.floating;
import io = watt.io;

import math = charge.math;

import charge.gfx;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.shaders;


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
class Pipeline
{
public:
	enum Kind
	{
		Points0,
		Points1,
		Raycube,
		CubePoint,
		Num,
	}


public:
	counters: GfxCounters;
	name: string;


protected:
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
		store := getStore(create.xShift, create.yShift, create.zShift);
		b := new StepsBuilder(store);

		final switch (kind) with (Kind) {
		case Points0:
			name = "points";
			makePointsPipeline(b, false);
			break;
		case Points1:
			name = "points";
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

		names: string[];
		foreach (i, step; mSteps) {
			names ~= step.name;
		}
		counters = new GfxCounters(names);

		// Setup the texture.
		mOctTexture = octTexture;

		// Setup a VAO.
		createIndexBuffer();
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
		buf0, buf3, buf6, buf9, buf11: u32;

		mSteps ~= b.makeInit(           out    buf0);
		mSteps ~= b.makeList1( buf0, 3, out    buf3);
		mSteps ~= b.makeList1( buf3, 3, out    buf6);
		mSteps ~= b.makeList1( buf6, 3, out    buf9);
		if (dub) {
			mSteps ~= b.makeListDouble(buf9, out buf11);
		} else {
			mSteps ~= b.makeList1(buf9, 2, out buf11);
		}
		mSteps ~= b.makePoints(buf11);
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
		mSteps ~= new ElementsStep(b.s, 0,      10, 1);
		mSteps ~= new ListStep(    b.s, 2, 0, 0, 7, 2, 0.0f);
		mSteps ~= new ElementsStep(b.s, 0,       9, 2);
	}

	fn close()
	{
	}

	fn draw(ref input: Draw)
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

		// Completely sync with the GPU, for timing.
		glFinish();

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
}
