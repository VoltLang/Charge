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
	DagBuffer vbo;
	GfxShader voxelShader;

	GLuint query;
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

		voxelShader = new GfxShader(voxelVertex450, voxelGeometry450,
			voxelFragment450, null, null);

		glGenQueries(1, &query);

		// Setup raytracing code.
		data := read("res/bunny_512x512x512.voxels");

		glGenBuffers(1, &octBuffer);
		glBindBuffer(GL_TEXTURE_BUFFER, octBuffer);
		glBufferData(GL_TEXTURE_BUFFER, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_TEXTURE_BUFFER, 0);

		glGenTextures(1, &octTexture);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glTexBuffer(GL_TEXTURE_BUFFER, GL_INTENSITY32UI_EXT, octBuffer);
		glBindTexture(GL_TEXTURE_BUFFER, 0);

		size_t max = 32;
		b := new DagBuilder(max * max * max);
		foreach (i; 0 .. max*max*max) {
			u32[3] vals;
			math.decode3(i, out vals);
			b.add(cast(u8)vals[0], cast(u8)vals[1], cast(u8)vals[2]);
		}
		vbo = DagBuffer.make("power/dag", b);
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


		rot := math.Quatf.opCall(rotationX, rotationY, 0.f);
		vec := rot * math.Vector3f.opCall(0.f, 0.f, -distance);
		pos := math.Point3f.opCall(0.5f, 0.5f, 0.5f) - vec;


		math.Matrix4x4f view;
		view.setToLookFrom(ref pos, ref rot);

		math.Matrix4x4f proj;
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 256.f);
		proj.setToMultiply(ref view);

		// Setup shader.
		voxelShader.bind();
		voxelShader.matrix4("matrix", 1, true, proj.ptr);
		voxelShader.float3("cameraPos".ptr, 1, pos.ptr);

		shouldEnd: bool;
		if (!queryInFlight) {
			glBeginQuery(GL_TIME_ELAPSED, query);
			shouldEnd = true;
		}

		// Draw the array.
		glCullFace(GL_BACK);
		glEnable(GL_CULL_FACE);
		glEnable(GL_PROGRAM_POINT_SIZE);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);

		glBindVertexArray(vbo.vao);
		glDrawArraysInstanced(GL_POINTS, 0, vbo.num, 1);//, 16*16*16);
		glBindVertexArray(0);

		glBindTexture(GL_TEXTURE_BUFFER, 0);
		glDisable(GL_PROGRAM_POINT_SIZE);
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

		str := `Info:
Elapsed time: %sms`;

		text := format(str, timeElapsed / 1_000_000_000.0 * 1_000.0);

		updateText(text);
	}
}

enum string voxelVertex450 = `
#version 450 core

layout (location = 0) in ivec3 inPosition;
layout (location = 1) in ivec3 inMod;

layout (location = 0) out ivec3 outPosition;


void main(void)
{
	outPosition = inPosition + inMod * 16;
}
`;

enum string voxelGeometry450 = `
#version 450 core

#define POW 5
#define DIVISOR pow(2, float(POW))
#define DIVISOR_INV (1.0/DIVISOR)

layout (points) in;
layout (location = 0) in ivec3[] inPosition;

layout (binding = 0) uniform isamplerBuffer octree;

//#define POINTS
#ifdef POINTS
layout (points, max_vertices = 1) out;
#else
layout (triangle_strip, max_vertices = 12) out;
#endif
layout (location = 0) out vec4 outColor;

uniform mat4 matrix;
uniform vec3 cameraPos;


bool findStart(ivec3 ipos, out int offset, out vec4 color)
{
	// Initial node address.
	offset = 0;

	// Subdivid until empty node or found the node for this box.
	for (int i = POW; i >= 0; i--) {
		// Get the node.
		uint node = uint(texelFetchBuffer(octree, offset).a);

		// Found color, return the voxol color.
		if ((node & uint(0x80000000)) >> uint(31) == uint(1)) {
			uint alpha = (node & uint(0x3F000000)) >> uint(24);
			uint red = (node & uint(0x00FF0000)) >> uint(16);
			uint green = (node & uint(0x0000FF00)) >> uint(8);
			uint blue = (node & uint(0x000000FF));
			color = vec4(red, green, blue, 255) / 255.0;
			return true;
		}

		// Found empty node, so return false to not emit a box.
		// We could have hit this if we hit a color.
		if ((node & uint(0xC0000000)) != uint(0)) {
			return false;
		}

		// 3D bit selector, each element is in the range [0, 1].
		ivec3 range = (ipos % (1 << i)) >> (i - 1);

		// Turn that into scalar in the range [0, 8].
		uint select = uint(dot(range, vec3(1, 2, 4)));

		// Use the selector and node pointer to get the new node position.
		offset = int((node & uint(0x3FFFFFFF)) + select);
	}

	color = vec4(ipos * DIVISOR_INV, 1.0);
	return true;
}

void emit(ivec3 ipos, vec3 off)
{
	vec3 pos = ipos;
	pos += off;
	pos *= DIVISOR_INV;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

void main(void)
{
	int outOffset;
	ivec3 ipos = inPosition[0];
	if (!findStart(ipos, outOffset, outColor)) {
		return;
	}

#ifdef POINTS
	gl_PointSize = 16.0;
	gl_Position = matrix * vec4(vec3(ipos) * DIVISOR_INV, 1.0);
	EmitVertex();
	EndPrimitive();
#else
	vec3 outMinEdge = vec3(ipos) * DIVISOR_INV;
	vec3 outMaxEdge = outMinEdge + vec3(1.0) * DIVISOR_INV;

	if (cameraPos.z < outMinEdge.z) {
		emit(ipos, vec3(1.0, 1.0, 0.0));
		emit(ipos, vec3(0.0, 1.0, 0.0));
		emit(ipos, vec3(1.0, 0.0, 0.0));
		emit(ipos, vec3(0.0, 0.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.z > outMaxEdge.z) {
		emit(ipos, vec3(0.0, 0.0, 1.0));
		emit(ipos, vec3(0.0, 1.0, 1.0));
		emit(ipos, vec3(1.0, 0.0, 1.0));
		emit(ipos, vec3(1.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y < outMinEdge.y) {
		emit(ipos, vec3(0.0, 0.0, 0.0));
		emit(ipos, vec3(0.0, 0.0, 1.0));
		emit(ipos, vec3(1.0, 0.0, 0.0));
		emit(ipos, vec3(1.0, 0.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y > outMaxEdge.y) {
		emit(ipos, vec3(1.0, 1.0, 1.0));
		emit(ipos, vec3(0.0, 1.0, 1.0));
		emit(ipos, vec3(1.0, 1.0, 0.0));
		emit(ipos, vec3(0.0, 1.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.x < outMinEdge.x) {
		emit(ipos, vec3(0.0, 0.0, 0.0));
		emit(ipos, vec3(0.0, 1.0, 0.0));
		emit(ipos, vec3(0.0, 0.0, 1.0));
		emit(ipos, vec3(0.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.x > outMaxEdge.x) {
		emit(ipos, vec3(1.0, 1.0, 1.0));
		emit(ipos, vec3(1.0, 1.0, 0.0));
		emit(ipos, vec3(1.0, 0.0, 1.0));
		emit(ipos, vec3(1.0, 0.0, 0.0));
		EndPrimitive();
	}
#endif
}
`;

enum string voxelFragment450 = `
#version 450 core

layout (location = 0) in vec4 inColor;
layout (location = 0) out vec4 outColor;


void main(void)
{
	outColor = inColor;
}
`;

/**
 * VBO used for boxed base voxels.
 */
class DagBuffer : GfxBuffer
{
public:
	GLsizei num;


public:
	global DagBuffer make(string name,(DagBuilder vb)
	{
		void* dummy;
		auto buffer = cast(DagBuffer)Resource.alloc(
			typeid(DagBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	void update(DagBuilder vb)
	{
		deleteBuffers();
		vb.bake(out vao, out buf, out num);
	}


protected:
	this(GLuint vao, GLuint buf)
	{
		super(vao, buf);
	}
}

struct Vertex
{
	ubyte x, y, z, w;
}


class DagBuilder : GfxBuilder
{
	this(size_t num)
	{
		reset(num);
	}

	final void reset(size_t num = 0)
	{
		resetStore(num * typeid(Vertex).size);
	}

	final void add(ubyte x, ubyte y, ubyte z)
	{
		Vertex vert;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.w = 0;

		add(&vert, 1);
	}

	final void add(Vertex* vert, size_t num)
	{
		add(cast(void*)vert, num * typeid(Vertex).size);
	}

	alias add = GfxBuilder.add;

	final void bake(out GLuint vao, out GLuint buf, out GLsizei num)
	{
		// Setup vertex buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		stride := cast(GLsizei)typeid(Vertex).size;
		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, stride, null);
		glVertexAttribDivisor(0, 0);
		glEnableVertexAttribArray(0);
		glVertexAttribIPointer(1, 4, GL_UNSIGNED_BYTE, stride, null);
		glVertexAttribDivisor(1, 1);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);

		num = cast(GLsizei)length / stride;
	}
}
