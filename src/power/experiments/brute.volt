// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.brute;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;
import io = watt.io;

import charge.ctl;
import charge.gfx;
import charge.core;
import charge.game;
import charge.sys.memory;
import charge.sys.resource;

import math = charge.math;

import power.voxel.boxel;
import power.voxel.dag;
import power.experiments.viewer;


class Brute : Viewer
{
public:
	DagBuffer first;
	DagBuffer second;
	DagBuffer third;
	IndirectBuffer ibo;
	GfxShader voxelShader;

	GLuint feedback;
	GfxShader feedbackShader;

	GLuint query;
	GLuint fbQuery;
	bool queryInFlight;


	/**
	 * For ray tracing.
	 * @{
	 */
	GLuint octBuffer;
	GLuint octTexture;
	/**
	 * @}
	 */


public:
	this(GameSceneManager g)
	{
		super(g);
		distance = 1.0;

		vert := cast(string)read("res/power/shaders/brute/voxel.vert.glsl");
		geom := cast(string)read("res/power/shaders/brute/voxel.geom.glsl");
		frag := cast(string)read("res/power/shaders/brute/voxel.frag.glsl");
		voxelShader = new GfxShader(vert, geom, frag, null, null);

		vert = cast(string)read("res/power/shaders/brute/feedback.vert.glsl");
		geom = cast(string)read("res/power/shaders/brute/feedback.geom.glsl");
		frag = cast(string)read("res/power/shaders/brute/feedback.frag.glsl");
		feedbackShader = new GfxShader(vert, geom, frag, null, null);

		glGenQueries(1, &query);
		glGenQueries(1, &fbQuery);

		// Setup raytracing code.
		data := read("res/bunny_512x512x512.voxels");

		glGenBuffers(1, &octBuffer);
		glBindBuffer(GL_TEXTURE_BUFFER, octBuffer);
		glBufferData(GL_TEXTURE_BUFFER, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_TEXTURE_BUFFER, 0);

		glGenTextures(1, &octTexture);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glTexBuffer(GL_TEXTURE_BUFFER, GL_R32UI, octBuffer);
		glBindTexture(GL_TEXTURE_BUFFER, 0);

		maxFirst : size_t = 1;
		maxSecond : size_t = cast(size_t)(8 * 8 * 8);
		maxThird : size_t = cast(size_t)(64 * 64 * 64);

		first = DagBuffer.make("power/dag/second", cast(GLsizei)maxFirst, maxFirst);
		second = DagBuffer.make("power/dag/second", cast(GLsizei)maxSecond, maxSecond);
		third = DagBuffer.make("power/dag/second", cast(GLsizei)maxThird, maxThird);
		ibo = IndirectBuffer.make("power/ido", 1, cast(GLuint)(8*8*8));
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close()
	{
		super.close();

		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
		if (voxelShader !is null) {
			voxelShader.breakApart();
			voxelShader = null;
		}
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override void renderScene(GfxTarget t)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);


		math.Matrix4x4f view;
		view.setToLookFrom(ref camPosition, ref camRotation);

		math.Matrix4x4f proj;
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 256.f);
		proj.setToMultiply(ref view);


		shouldEnd: bool;
		if (!queryInFlight) {
			glBeginQuery(GL_TIME_ELAPSED, query);
			shouldEnd = true;
		}

		// Draw the array.
		glCullFace(GL_BACK);
		glEnable(GL_CULL_FACE);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);

		// Setup shader.
		feedbackShader.bind();

		//
		// First feedback step
		//
		glEnable(GL_RASTERIZER_DISCARD);
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, second.buf);

		glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, fbQuery);
		glBeginTransformFeedback(GL_POINTS);
		glBindVertexArray(first.vao);
		glDrawArrays(GL_POINTS, 0, 8*8*8);
		glBindVertexArray(0);
		glEndTransformFeedback();
		glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);

		// Feedback the number of read objects into indirect buffer.
		glBindBuffer(GL_QUERY_BUFFER, ibo.buf);
		glGetQueryObjectuiv(fbQuery, GL_QUERY_RESULT, (cast(GLuint*)null) + 1);
		glBindBuffer(GL_QUERY_BUFFER, 0);

		//
		// Second feedback stage
		//
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, third.buf);
		glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, fbQuery);
		glBeginTransformFeedback(GL_POINTS);

		glBindVertexArray(second.vao);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, ibo.buf);
		glDrawArraysIndirect(GL_POINTS, null);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindVertexArray(0);

		glEndTransformFeedback();
		glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);

		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, 0);
		glDisable(GL_RASTERIZER_DISCARD);

		// Feedback the number of read objects into indirect buffer.
		glBindBuffer(GL_QUERY_BUFFER, ibo.buf);
		glGetQueryObjectuiv(fbQuery, GL_QUERY_RESULT, (cast(GLuint*)null) + 1);
		glBindBuffer(GL_QUERY_BUFFER, 0);

		// Setup shader.
		voxelShader.bind();
		voxelShader.matrix4("matrix", 1, true, proj.ptr);
		voxelShader.float3("cameraPos".ptr, 1, camPosition.ptr);

		// Draw voxels
		glEnable(GL_PROGRAM_POINT_SIZE);
		glBindVertexArray(third.vao);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, ibo.buf);
		glDrawArraysIndirect(GL_POINTS, null);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindVertexArray(0);
		glDisable(GL_PROGRAM_POINT_SIZE);

		glBindTexture(GL_TEXTURE_BUFFER, 0);
		glDisable(GL_CULL_FACE);

		if (shouldEnd) {
			glEndQuery(GL_TIME_ELAPSED);
			queryInFlight = true;
		}

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);

		// Check for last frames query.
		checkQuery();
	}

	void checkQuery()
	{
		if (!queryInFlight) {
			return;
		}

		available: GLint;
		glGetQueryObjectiv(query, GL_QUERY_RESULT_AVAILABLE, &available);
		if (!available) {
			return;
		}

		timeElapsed: GLuint64;
		glGetQueryObjectui64v(query, GL_QUERY_RESULT, &timeElapsed);
		queryInFlight = false;

		str := "Info:\nElapsed time: %sms";

		text := format(str, timeElapsed / 1_000_000_000.0 * 1_000.0);

		updateText(text);
	}
}

struct IndirectData
{
	GLuint count;
	GLuint instanceCount;
	GLuint first;
	GLuint baseInstance;
}

/**
 * Inderect buffer used for drawing.
 */
class IndirectBuffer : Resource
{
public:
	GLuint buf;
	GLsizei num;


public:
	global IndirectBuffer make(string name, GLsizei num, GLuint count)
	{
		void* dummy;
		auto buffer = cast(IndirectBuffer)Resource.alloc(
			typeid(IndirectBuffer), GfxBuffer.uri, name, 0, out dummy);
		buffer.__ctor(num, count);
		return buffer;
	}


protected:
	this(GLsizei num, GLuint count)
	{
		super();
		this.num = num;

		IndirectData data;
		data.count = count;
		data.instanceCount = 1;

		indirectStride := cast(GLsizei)typeid(IndirectData).size;
		indirectLength := num * indirectStride;

		// First allocate the storage.
		glCreateBuffers(1, &buf);
		glNamedBufferStorage(buf, indirectLength, null, GL_DYNAMIC_STORAGE_BIT);

		// Then fill out the first slot.
		glNamedBufferSubData(buf, 0, indirectStride, cast(void*)&data);

		glCheckError();
	}

	~this()
	{
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
	}
}


struct InstanceData
{
	uint position, offset;
}

/**
 * VBO used for boxed base voxels.
 */
class DagBuffer : GfxBuffer
{
public:
	GLsizei num;

public:
	global DagBuffer make(string name, GLsizei num, size_t instances)
	{
		void* dummy;
		auto buffer = cast(DagBuffer)Resource.alloc(
			typeid(DagBuffer), uri, name, 0, out dummy);
		buffer.__ctor(num, instances);
		return buffer;
	}

protected:
	this(GLsizei num, size_t instances)
	{
		super(0, 0);
		this.num = num;

		// Setup instance buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);

		glBindBuffer(GL_ARRAY_BUFFER, buf);

		instanceStride := cast(GLsizei)typeid(InstanceData).size;
		instancesLength := cast(GLsizei)instances * instanceStride;
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)instancesLength, null, GL_STATIC_DRAW);

		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glVertexAttribDivisor(0, 1);
		glVertexAttribDivisor(1, 1);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);
	}
}
