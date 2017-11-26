// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.steps;

import watt.text.format;

import lib.gl.gl45;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;

import voxel.svo.shaders;


/*!
 * Helper class to make shaders.
 */
struct ResourceTracker
{
	store: ShaderStore;
	baseIndex: u32;
	counterIndex: u32;

	steps: Step[];

	fn addInit(out s: Step)
	{
		s = new InitStep(baseIndex, counterIndex);

		counterIndex += 1;
		baseIndex += StepState.VoxelBufferStepSize;
		steps ~= s;
	}

	fn addFrustum(out s: Step, src: Step, powerLevels: u32)
	{
		s = new FrustumStep(
			store, src, baseIndex, counterIndex, powerLevels);

		counterIndex += 1;
		baseIndex += StepState.VoxelBufferStepSize;
		steps ~= s;
	}

	fn addSplit(out s: Step, out o: Step, src: Step, splitIndex: u32)
	{
		s = new SplitStep(
			store, src, baseIndex, counterIndex, splitIndex);
		steps ~= s;

		counterIndex += 1u;
		baseIndex += StepState.VoxelBufferStepSize;

		makeDummy(out o, s.finalLevel);
	}

	fn addSortToDoubleToPoint(src: Step)
	{
		steps ~= new SortToDoubleToPointStep(
			store, src, baseIndex);

		baseIndex += StepState.VoxelBufferStepSize;
	}

	fn addSortToDoubleToCube(src: Step)
	{
		steps ~= new SortToDoubleToCubeStep(
			store, src, baseIndex);

		baseIndex += StepState.VoxelBufferStepSize;
	}


	fn makeDummy(out s: Step, finalLevel: u32)
	{
		s = new DummyStep(baseIndex, counterIndex, finalLevel);

		counterIndex += 1u;
		baseIndex += StepState.VoxelBufferStepSize;
	}
}

/*!
 * The state that is passed to each step when we are running the pipeline.
 */
struct StepState
{
public:
	enum VoxelBufferStepSize : size_t = 2 * 1024 * 1024;

	enum CountersBufferBinding = 0;
	enum DataBufferBinding = 1;
	enum VoxelBufferBinding = 2;
	enum SortBufferBinding = 3;
	enum DoubleBufferBinding = 4;
	enum DrawIndirectBinding = 7;


public:
	voxelBuffer: GLuint;
	sortBuffer: GLuint;
	doubleBuffer: GLuint;

	dataBuffer: GLuint;
	atomicBuffer: GLuint;
	countersBuffer: GLuint;
	drawIndirectBuffer: GLuint;
	computeIndirectBuffer: GLuint;
}

abstract class Step
{
public:
	baseIndex: u32;
	counterIndex: u32;
	finalLevel: u32;


public:
	abstract fn run(ref state: StepState);
}

class DummyStep : Step
{
public:
	this(baseIndex: u32, counterIndex: u32, finalLevel: u32)
	{
		this.baseIndex = baseIndex;
		this.counterIndex = counterIndex;
		this.finalLevel = finalLevel;
	}

	override fn run(ref state: StepState)
	{
		assert(false);
	}
}

class InitStep : Step
{
public:
	this(baseIndex: u32, counterIndex: u32)
	{
		this.baseIndex = baseIndex;
		this.counterIndex = counterIndex;
		this.finalLevel = 0u;
	}

	override fn run(ref state: StepState)
	{

	}
}

class BaseWalkStep : Step
{
public:
	src: Step;
	shader: gfx.Shader;
	timeTracker: gfx.TimeTracker;


public:
	override fn run(ref state: StepState)
	{
		// Get some data from the source step.
		srcBaseIndex := src.baseIndex;
		srcCounterIndex := src.counterIndex;

		this.timeTracker.exchange();
		// Copy the counter from the previous run.
		off := cast(GLintptr)(srcCounterIndex * 4);
		glCopyNamedBufferSubData(state.countersBuffer, state.computeIndirectBuffer, off, 0, 4);

		this.shader.bind();
		glDispatchComputeIndirect(0u);

		glCheckError();
	}
}

class FrustumStep : BaseWalkStep
{
	this(store: ShaderStore, src: Step, baseIndex: u32, counterIndex: u32, powerLevels: u32)
	{
		srcBaseIndex := src.baseIndex;
		dstBaseIndex := baseIndex;

		startPower := src.finalLevel;
		finalLevel := startPower + powerLevels;
		name := format("frustum %s-%s", startPower, finalLevel);

		this.src = src;
		this.baseIndex = baseIndex;
		this.counterIndex = counterIndex;
		this.finalLevel = finalLevel;
		this.timeTracker = new gfx.TimeTracker(name);
		this.shader = store.makeWalkFrustumShader(
			srcBaseIndex: srcBaseIndex,
			dstBaseIndex: dstBaseIndex,
			counterIndex: counterIndex,
			powerStart: startPower,
			powerLevels: powerLevels);
	}
}

class SplitStep : BaseWalkStep
{
	this(store: ShaderStore, src: Step, baseIndex: u32, counterIndex: u32, splitIndex: u32)
	{
		srcBaseIndex := src.baseIndex;
		dstBaseIndex := baseIndex;

		powerLevels := 1u;
		startPower := src.finalLevel;
		finalLevel := startPower + powerLevels;
		name := format("split %s-%s", startPower, finalLevel);

		this.src = src;
		this.baseIndex = baseIndex;
		this.counterIndex = counterIndex;
		this.finalLevel = finalLevel;
		this.timeTracker = new gfx.TimeTracker(name);
		this.shader = store.makeWalkSplitShader(
			srcBaseIndex: srcBaseIndex,
			dstBaseIndex: dstBaseIndex,
			counterIndex: counterIndex,
			splitIndex: splitIndex,
			splitSize: StepState.VoxelBufferStepSize,
			powerStart: startPower);
	}
}

class SortToDoubleToPointStep : BaseWalkStep
{
public:
	doubleTime: gfx.TimeTracker;
	doubleShader: gfx.Shader;

	pointsTime: gfx.TimeTracker;
	pointsShader: gfx.Shader;


public:
	this(store: ShaderStore, src: Step, baseIndex: u32)
	{
		srcBaseIndex := src.baseIndex;

		powerLevels := 4u;
		startPower := src.finalLevel;
		finalLevel := startPower + powerLevels;
		name := format("sort %s-%s", startPower, startPower + 2u);

		this.src = src;
		this.baseIndex = baseIndex;
		this.counterIndex = u32.max;
		this.finalLevel = finalLevel;
		this.timeTracker = new gfx.TimeTracker(name);
		this.shader = store.makeWalkSortShader(srcBaseIndex: srcBaseIndex, counterIndex: 1, powerStart: startPower);

		// Double
		doubleTime = new gfx.TimeTracker(format("double %s-%s", startPower + 2u, finalLevel));
		doubleShader = store.makeWalkDoubleShader(counterIndex: 0);

		// Points
		pointsTime = new gfx.TimeTracker(format("points %s", finalLevel));
		pointsShader = store.makePointsWalkShader(powerStart: finalLevel);
	}

	override fn run(ref state: StepState)
	{

		super.run(ref state);

		// Track time to double and copy the counter.
		this.doubleTime.exchange();
		glCopyNamedBufferSubData(state.atomicBuffer, state.computeIndirectBuffer, 4, 0, 4);
		this.doubleShader.bind();
		glDispatchComputeIndirect(0u);

		// Track time to points, copy the counter and reset the counter.
		this.pointsTime.exchange();
		glCopyNamedBufferSubData(state.atomicBuffer, state.drawIndirectBuffer, 0, 0, 4);
		glNamedBufferSubData(state.atomicBuffer, 0, 4 * 2, cast(void*)[0, 0].ptr);

		this.pointsShader.bind();
		glEnable(GL_PROGRAM_POINT_SIZE);
		glDrawArraysIndirect(GL_POINTS, null);
		glDisable(GL_PROGRAM_POINT_SIZE);

		glCheckError();
	}
}

class SortToDoubleToCubeStep : BaseWalkStep
{
public:
	doubleTime: gfx.TimeTracker;
	doubleShader: gfx.Shader;

	dispatchShader: gfx.Shader;

	cubesTime: gfx.TimeTracker;
	cubesShader: gfx.Shader;


public:
	this(store: ShaderStore, src: Step, baseIndex: u32)
	{
		srcBaseIndex := src.baseIndex;

		powerLevels := 4u;
		startPower := src.finalLevel;
		finalLevel := startPower + powerLevels;
		name := format("sort %s-%s", startPower, startPower + 2u);

		this.src = src;
		this.baseIndex = baseIndex;
		this.counterIndex = u32.max;
		this.finalLevel = finalLevel;
		this.timeTracker = new gfx.TimeTracker(name);
		this.shader = store.makeWalkSortShader(srcBaseIndex: srcBaseIndex, counterIndex: 1, powerStart: startPower);

		// Double
		this.doubleTime = new gfx.TimeTracker(format("double %s-%s", startPower + 2u, finalLevel));
		this.doubleShader = store.makeWalkDoubleShader(counterIndex: 0);

		// Points
		cubesTime = new gfx.TimeTracker(format("cubes %s", finalLevel));

		dispatchShader = store.makeElementsDispatchShader(src: 0, dst: StepState.DrawIndirectBinding);
		cubesShader = store.makeCubesWalkShader(src: 4, powerStart: finalLevel);
	}

	override fn run(ref state: StepState)
	{
		super.run(ref state);

		// Track time to double and copy the counter.
		this.doubleTime.exchange();
		glCopyNamedBufferSubData(state.atomicBuffer, state.computeIndirectBuffer, 4, 0, 4);
		this.doubleShader.bind();
		glDispatchComputeIndirect(0u);

		// Track time to points, copy the counter and reset the counter.
		this.cubesTime.exchange();
		//glCopyNamedBufferSubData(state.atomicBuffer, state.DrawIndirect, 0, 0, 4);

		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);
		glNamedBufferSubData(state.atomicBuffer, 0, 4 * 2, cast(void*)[0, 0].ptr);

		this.cubesShader.bind();
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);

		glCheckError();
	}
}
