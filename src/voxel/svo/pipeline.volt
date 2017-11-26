// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.pipeline;

import io = watt.io;

import watt.algorithm;
import watt.text.string;
import watt.text.format;
import watt.math.floating;

import lib.gl.gl45;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl : glCheckError;

import old = voxel.old;

import voxel.svo.util;
import voxel.svo.steps;
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

	// For shaders.
	if (!GL_ARB_shader_atomic_counter_ops && !GL_AMD_shader_atomic_counter_ops) {
		str ~= "Need GL_ARB_shader_atomic_counter_ops\n";
		str ~=  " or GL_AMD_shader_atomic_counter_ops\n";
	}

	return str;
}

struct Draw
{
	camVP: math.Matrix4x4d;
	cullVP: math.Matrix4x4d;
	camPos: math.Point3f; _pad0: f32;
	cullPos: math.Point3f; _pad1: f32;
	targetWidth, targetHeight: u32; fov: f32; _pad2: f32;
	objs: Entity[];
}



struct DataBuffer
{
public:
	static struct Entry
	{
		xy: u32;
		zobj: u32;
		addr: u32;

		fn from(id: u32, start: u32)
		{
			this.xy = 0;
			this.zobj = id << 16u;
			this.addr = start;
		}
	}

	static struct PerObject
	{
		matrix: math.Matrix4x4f;
		planes: math.Planef[4];
		camPosition: math.Point3f; _pad0: f32;
	};


public:
	objs: PerObject[256];
	dists: f32[32];
	pointScale: f32;
	nums: u32[16];
	entries: Entry[256][16];


public:
	fn setFrom(ref input: Draw)
	{
		fov := radians(cast(f64)input.fov);
		height := cast(f64)input.targetHeight;

		dist: VoxelDistanceFinder;
		dist.setup(fov, input.targetHeight, input.targetWidth);
		foreach (i, ref d; dists) {
			d = cast(f32)dist.getDistance(cast(i32)i);
		}

		// Shared point scaler.
		pointScale = cast(f32)(height / (2.0 * tan(fov / 2.0)));


		foreach (i, obj; input.objs) {
			updateState(
				ref objs[i],
				ref input.camVP,
				ref input.cullVP,
				ref input.cullPos,
				obj);
			id := cast(u32) i;
			level := obj.numLevels;
			num := nums[level]++;
			entries[level][num].from(id, obj.start);
		}
	}

	global fn updateState(ref outObj: PerObject,
	                      ref camVp: math.Matrix4x4d,
	                      ref cullVp: math.Matrix4x4d,
	                      ref cullCamPos: math.Point3f,
	                      model: Entity)
	{
		rot := model.rot;
		pos := model.pos;

		off: math.Vector3f;
		offPos := pos - off;

		m: math.Matrix4x4d;
		m.setToModel(ref offPos, ref rot);

		vec := model.rot.inverse() * (cullCamPos - offPos);
		offCamPos := math.Point3f.opCall(vec);

		cullMVP: math.Matrix4x4d;
		cullMVP.setToMultiply(ref cullVp, ref m);

		frustum: math.Frustum;
		frustum.setFromUntransposedGL(ref cullMVP);

		outObj.matrix.setToMultiplyAndTranspose(ref camVp, ref m);
		outObj.planes[0].setFrom(ref frustum.p[0]);
		outObj.planes[1].setFrom(ref frustum.p[1]);
		outObj.planes[2].setFrom(ref frustum.p[2]);
		outObj.planes[3].setFrom(ref frustum.p[3]);
		outObj.camPosition = offCamPos;
	}

	fn setFrom(ref input: old.Draw)
	{
		frustum: math.Frustum;
		frustum.setFromUntransposedGL(ref input.cullMVP);
		height := cast(f64)input.targetHeight;
		fov := radians(cast(f64)input.fov);

		dist: VoxelDistanceFinder;
		dist.setup(fov, input.targetHeight, input.targetWidth);
		foreach (i, ref d; dists) {
			d = cast(f32)dist.getDistance(cast(i32)i);
		}

		nums[input.numLevels] = 1u;
		entries[input.numLevels][0].from(id: 0, start: input.frame);

		// Shared point scaler.
		pointScale = cast(f32)(height / (2.0 * tan(fov / 2.0)));

		objs[0].matrix.setToAndTranspose(ref input.camMVP);
		objs[0].camPosition = input.cullPos;
		objs[0].planes[0].setFrom(ref frustum.p[0]);
		objs[0].planes[1].setFrom(ref frustum.p[1]);
		objs[0].planes[2].setFrom(ref frustum.p[2]);
		objs[0].planes[3].setFrom(ref frustum.p[3]);
	}
}

/*!
 * A single SVO rendering pipeline.
 */
class Pipeline : old.Pipeline
{
public:
	data: Data;


protected:
	mStore: ShaderStore;

	mVAO: GLuint;

	mState: StepState;

	enum DataBufferSize = cast(u32)(typeid(DataBuffer).size);
	enum AtomicBufferSize = 4 * 8;
	enum CounterBufferSize = 4 * 128;
	enum DrawIndirectSize = 4 * 5;
	enum DispatchIndirectSize = 4 * 3;
	enum VoxelBufferSize : size_t = 512 * 1024 * 1024;

	// Yes they really need to be this big.
	enum SortBufferSize : size_t = 8 * 1024 * 1024;
	enum DoubleBufferSize : size_t = 128 * 1024 * 1024;

	mTimeInit: gfx.TimeTracker;
	mTimeClose: gfx.TimeTracker;

	mSteps: Step[];
	mStart: Step[16];


public:
	this(data: Data)
	{
		this.data = data;
		this.mStore = getStore(ref data.create);
		super("test");

		mTimeInit = new gfx.TimeTracker("init");
		mTimeClose = new gfx.TimeTracker("close");

		numLevels := 11u;
		if (numLevels >= 16) {
			assert(false, "to many levels");
		}

		tmp, cubes, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13: Step;

		rt: ResourceTracker;
		rt.store = mStore;
		rt.addInit(out mStart[numLevels]);
		si := 7u;

		if (numLevels >= 15) {
			rt.addSplit(  s: out mStart[14], o: out  s3, src: mStart[15],  splitIndex: si++);
		}

		if (numLevels >= 14) {
			rt.addSplit(  s: out mStart[13], o: out  s4, src: mStart[14],  splitIndex: si++);
		}

		if (numLevels >= 13) {
			rt.addSplit(  s: out mStart[12], o: out  s5, src: mStart[13],  splitIndex: si++);
		}

		if (numLevels >= 12) {
			rt.addSplit(  s: out mStart[11], o: out  s6, src: mStart[12],  splitIndex: si++);
		}

		if (numLevels >= 11) {
			rt.addSplit(  s: out mStart[10], o: out  s7, src: mStart[11],  splitIndex: si++);
		}

		if (numLevels >= 10) {
			rt.addSplit(  s: out mStart[ 9], o: out  s8, src: mStart[10],  splitIndex: si++);
		}

		if (numLevels >= 9) {
			rt.addSplit(  s: out mStart[ 8], o: out  s9, src: mStart[9],  splitIndex: si++);
		}

		rt.addSplit(  s: out mStart[ 7], o: out s10, src: mStart[ 8],  splitIndex: si++);
		rt.addSplit(  s: out mStart[ 6], o: out s11, src: mStart[ 7],  splitIndex: si++);
		rt.addSplit(  s: out mStart[ 5], o: out s12, src: mStart[ 6],  splitIndex: si++);
		rt.addSplit(  s: out      cubes, o: out s13, src: mStart[ 5],  splitIndex: si + 2);

		// Closest voxels.
		rt.addSortToDoubleToCube(cubes);

		// Second closest voxels.
		rt.addSortToDoubleToPoint(s13);

		// And so on.
		rt.addSortToDoubleToPoint(s12);
		rt.addSortToDoubleToPoint(s11);
		rt.addSortToDoubleToPoint(s10);

		if (numLevels >= 9) {
			rt.addSortToDoubleToPoint(s9);
		}

		if (numLevels >= 10) {
			rt.addSortToDoubleToPoint(s8);
		}

		mSteps = rt.steps;

		// Setup a VAO.
		mIndexBuffer := createIndexBuffer(662230u);
		glCreateVertexArrays(1, &mVAO);
		glVertexArrayElementBuffer(mVAO, mIndexBuffer);

		// Create the storage for the atmic buffer.
		glCreateBuffers(1, &mState.atomicBuffer);
		glNamedBufferStorage(mState.atomicBuffer, AtomicBufferSize, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mState.atomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Create the storage for the command buffer.
		glCreateBuffers(1, &mState.computeIndirectBuffer);
		glNamedBufferStorage(mState.computeIndirectBuffer, DispatchIndirectSize, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mState.computeIndirectBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Create the storage for the command buffer.
		glCreateBuffers(1, &mState.drawIndirectBuffer);
		glNamedBufferStorage(mState.drawIndirectBuffer, DrawIndirectSize, null, GL_DYNAMIC_STORAGE_BIT);
		glClearNamedBufferData(mState.drawIndirectBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);

		// Create the storage for the counter buffer.
		glCreateBuffers(1, &mState.countersBuffer);
		glNamedBufferStorage(mState.countersBuffer, CounterBufferSize, null, GL_DYNAMIC_STORAGE_BIT);

		// Create the storage for the data buffer.
		glCreateBuffers(1, &mState.dataBuffer);
		glNamedBufferStorage(mState.dataBuffer, DataBufferSize, null, GL_DYNAMIC_STORAGE_BIT);

		// Really big data buffer.
		glCreateBuffers(1, &mState.voxelBuffer);
		glNamedBufferStorage(mState.voxelBuffer, VoxelBufferSize, null, GL_DYNAMIC_STORAGE_BIT);


		glCreateBuffers(1, &mState.sortBuffer);
		glNamedBufferStorage(mState.sortBuffer, SortBufferSize, null, GL_DYNAMIC_STORAGE_BIT);

		glCreateBuffers(1, &mState.doubleBuffer);
		glNamedBufferStorage(mState.doubleBuffer, DoubleBufferSize, null, GL_DYNAMIC_STORAGE_BIT);
	}

	override fn close()
	{

	}

	alias draw = old.Pipeline.draw;

	fn draw(ref input: Draw)
	{
		mTimeTrackerRoot.start();

		state: DataBuffer;
		state.setFrom(ref input);

		doDraw(ref state);

		mTimeTrackerRoot.stop();
	}

	override fn doDraw(ref input: old.Draw)
	{
		state: DataBuffer;
		state.setFrom(ref input);
		doDraw(ref state);
	}

	fn doDraw(ref state: DataBuffer)
	{
		// Start counting the voxel time.
		mTimeInit.start();

		// Clear any error state.
		glCheckError();

		// General bindigns.
		glBindTextureUnit(0, data.texture);

		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, mState.drawIndirectBuffer);
		glBindBuffer(GL_DISPATCH_INDIRECT_BUFFER, mState.computeIndirectBuffer);
		glBindBufferBase(GL_ATOMIC_COUNTER_BUFFER, 0, mState.atomicBuffer);

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, StepState.CountersBufferBinding, mState.countersBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, StepState.DataBufferBinding, mState.dataBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, StepState.VoxelBufferBinding, mState.voxelBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, StepState.SortBufferBinding, mState.sortBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, StepState.DoubleBufferBinding, mState.doubleBuffer);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, StepState.DrawIndirectBinding, mState.drawIndirectBuffer);
		glBindVertexArray(mVAO);

		// Clear and setup buffers.
		glClearNamedBufferData(mState.atomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glClearNamedBufferData(mState.countersBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(mState.dataBuffer, 0, DataBufferSize, cast(void*)&state);
		glNamedBufferSubData(mState.drawIndirectBuffer, 0, 4 * 4, cast(void*)[0, 1, 0, 0, 0].ptr);
		glNamedBufferSubData(mState.computeIndirectBuffer, 0, 4 * 3, cast(void*)[0, 1, 1].ptr);

		foreach (i, ref es; state.entries) {
			num := state.nums[i];
			if (num <= 0) {
				continue;
			}

			entriesPtr := cast(void*)&es;
			entriesOff := cast(GLintptr)(mStart[i].baseIndex * 4);
			entriesSize := cast(GLintptr)(typeid(DataBuffer.Entry).size * num);
			numPtr := cast(void*)&state.nums[i];
			numOff := cast(GLintptr)(mStart[i].counterIndex * 4);
			numSize := cast(GLintptr)4;

			glNamedBufferSubData(mState.voxelBuffer, entriesOff, entriesSize, entriesPtr);
			glNamedBufferSubData(mState.countersBuffer, numOff, numSize, numPtr);
		}

		glCheckError();

		// Init counts as 0, skip it.
		foreach (step; mSteps[1 .. $]) {
			step.run(ref mState);
		}

		// Final closing step.
		mTimeClose.exchange();

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

		// Stop counting.
		mTimeClose.stop();

		// Debug
		glCheckError();
	}


private:
	fn debugCounter(src: u32) u32
	{
		val: u32[1];
		readBuffer(mState.countersBuffer, src, val);
		return val[0];
	}

	fn debugAtomic(src: u32) u32
	{
		val: u32[1];
		readBuffer(mState.atomicBuffer, src, val);
		return val[0];
	}

	fn printCounters()
	{
		val: u32[8];
		readBuffer(mState.countersBuffer, 0, val);
		io.output.writef( "| %8s | %8s | %8s | %8s |", val[0], val[1], val[2], val[3]);
		io.output.writefln(" %8s | %8s | %8s | %8s |", val[4], val[5], val[6], val[7]);
	}

	fn readBuffer(buf: GLuint, offset: u32, data: scope u32[])
	{
		glOffset := cast(GLintptr)(offset * 4);
		glSize := cast(GLsizei)(data.length * 4);
		glPtr := cast(void*)data.ptr;
		glGetNamedBufferSubData(buf, glOffset, glSize, glPtr);
	}
}
