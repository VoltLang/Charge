// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.raytracer;

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

void loadDag(string filename, out void[] data)
{
	// Setup raytracing code.
	data = read(filename);
	f32ptr := cast(f32*)data.ptr;
	u32ptr := cast(u32*)data.ptr;
	u64ptr := cast(u64*)data.ptr;

	id := u64ptr[0];
	frames := u64ptr[1];
	resolution := u64ptr[2];
	dataSizeInU32 := u64ptr[3];
	minX := f32ptr[ 8];
	minY := f32ptr[ 9];
	minZ := f32ptr[10];
	maxX := f32ptr[11];
	maxY := f32ptr[12];
	maxZ := f32ptr[13];

	// Calculate offset to data, both values are orignally in u32s.
	offset := (frames + 14UL) * 4;
	data = data[offset .. offset + dataSizeInU32 * 4];

/*
	io.writefln("id:         %016x", id);
	io.writefln("frames:     %s", frames);
	io.writefln("resolution: %s", resolution);
	io.writefln("ndwords:    %s", dataSizeInU32);
	io.writefln("rootMin:    %s %s %s", cast(f64)minX, cast(f64)minY, cast(f64)minZ);
	io.writefln("rootMax:    %s %s %s", cast(f64)maxX, cast(f64)maxY, cast(f64)maxZ);

	io.writefln("%s %s", dataSizeInU32 * 4, data.length);
	foreach (i; 0U .. 128U) {
		io.writefln("%04x: %08x", i, u32ptr[(offset / 4) + i]);
	}
*/
}

class RayTracer : Viewer
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

		void[] data;
		loadDag("res/alley.dag", out data);

		glGenBuffers(1, &octBuffer);
		glBindBuffer(GL_TEXTURE_BUFFER, octBuffer);
		glBufferData(GL_TEXTURE_BUFFER, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_TEXTURE_BUFFER, 0);

		glGenTextures(1, &octTexture);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glTexBuffer(GL_TEXTURE_BUFFER, GL_INTENSITY32UI_EXT, octBuffer);
		glBindTexture(GL_TEXTURE_BUFFER, 0);

		size_t max = 64;
		b := new DagBuilder(max * max * max);
		foreach (i; 0 .. max*max*max) {
			u32[3] vals;
			math.decode3(i, out vals);
			b.add(cast(u8)vals[0], cast(u8)vals[1], cast(u8)vals[2], 1);
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
		t.setMatrixToProjection(ref proj, 45.f, 0.0001f, 256.f);
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
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);

		glBindVertexArray(vbo.vao);
		glDrawArrays(GL_POINTS, 0, vbo.num);
		glBindVertexArray(0);

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

		str := `Info:
Elapsed time: %sms`;

		text := format(str, timeElapsed / 1_000_000_000.0 * 1_000.0);

		updateText(text);
	}
}

enum string voxelVertex450 = `
#version 450 core

layout (location = 0) in vec3 inPosition;

void main(void)
{
	gl_Position = vec4(inPosition, 1.0);
}
`;

enum string voxelGeometry450 = `
#version 450 core

#define POW 6
#define DIVISOR pow(2, float(POW))
#define DIVISOR_INV (1.0/DIVISOR)

layout (points) in;

layout (binding = 0) uniform isamplerBuffer octree;

layout (triangle_strip, max_vertices = 12) out;

layout (location = 0) out vec3 outPosition;
layout (location = 1) out vec3 outMinEdge;
layout (location = 2) out vec3 outMaxEdge;
layout (location = 3) out flat int outOffset;

uniform mat4 matrix;
uniform vec3 cameraPos;


void emit(vec3 off)
{
	vec3 pos = gl_in[0].gl_Position.xyz;
	pos += off;
	pos *= DIVISOR_INV;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

bool findStart(vec3 pos, out int offset)
{
	// Which part of the space the voxel volume occupy.
	vec3 boxMin = vec3(0.0);
	vec3 boxDim = vec3(1.0);

	// Initial node address.
	offset = 0;

	// Subdivid until empty node or found the node for this box.
	for (int i = POW; i > 0; i--) {
		// Get the node.
		uint node = uint(texelFetchBuffer(octree, offset).a);

		boxDim *= 0.5f;
		vec3 s = step(boxMin + boxDim, pos);
		boxMin = boxMin + boxDim * s;
		uint select = uint(dot(s, vec3(4, 1, 2)));
		if ((node & (uint(1) << select)) == uint(0)) {
			return false;
		}

		int bits = int(select + 1);
		uint toCount = bitfieldExtract(node, 0, bits);
		int address = int(bitCount(toCount));
		address += int(offset);

		offset = texelFetchBuffer(octree, address).a;
	}

	return true;
}

void main(void)
{
	vec3 pos = gl_in[0].gl_Position.xyz;
	outMinEdge = pos * DIVISOR_INV;
	outMaxEdge = outMinEdge + vec3(1.0) * DIVISOR_INV;

	if (!findStart(outMinEdge, outOffset)) {
		return;
	}

	if (cameraPos.z < outMinEdge.z) {
		emit(vec3(1.0, 1.0, 0.0));
		emit(vec3(0.0, 1.0, 0.0));
		emit(vec3(1.0, 0.0, 0.0));
		emit(vec3(0.0, 0.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.z > outMaxEdge.z) {
		emit(vec3(0.0, 0.0, 1.0));
		emit(vec3(0.0, 1.0, 1.0));
		emit(vec3(1.0, 0.0, 1.0));
		emit(vec3(1.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y < outMinEdge.y) {
		emit(vec3(0.0, 0.0, 0.0));
		emit(vec3(0.0, 0.0, 1.0));
		emit(vec3(1.0, 0.0, 0.0));
		emit(vec3(1.0, 0.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y > outMaxEdge.y) {
		emit(vec3(1.0, 1.0, 1.0));
		emit(vec3(0.0, 1.0, 1.0));
		emit(vec3(1.0, 1.0, 0.0));
		emit(vec3(0.0, 1.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.x < outMinEdge.x) {
		emit(vec3(0.0, 0.0, 0.0));
		emit(vec3(0.0, 1.0, 0.0));
		emit(vec3(0.0, 0.0, 1.0));
		emit(vec3(0.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.x > outMaxEdge.x) {
		emit(vec3(1.0, 1.0, 1.0));
		emit(vec3(1.0, 1.0, 0.0));
		emit(vec3(1.0, 0.0, 1.0));
		emit(vec3(1.0, 0.0, 0.0));
		EndPrimitive();
	}
}
`;

enum string voxelFragment450 = `
#version 450 core
#define MAX_ITERATIONS 500

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inMinEdge;
layout (location = 2) in vec3 inMaxEdge;
layout (location = 3) in flat int inOffset;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;


vec3 rayAABBTest(vec3 rayOrigin, vec3 rayDir, vec3 aabbMin, vec3 aabbMax)
{
	float tMin, tMax;

	// Project ray through aabb
	vec3 invRayDir = 1.0 / rayDir;
	vec3 t1 = (aabbMin - rayOrigin) * invRayDir;
	vec3 t2 = (aabbMax - rayOrigin) * invRayDir;
	
	vec3 tmin = min(t1, t2);
	vec3 tmax = max(t1, t2);
	
	tMin = max(max(0.0, tmin.x), max(tmin.y, tmin.z));
	tMax = min(min(99999.0, tmax.x), min(tmax.y, tmax.z));
	
	vec3 result;
	result.x = (tMax > tMin) ? 1.0 : 0.0;
	result.y = tMin;
	result.z = tMax;
	return result;
}

bool trace(out vec4 finalColor, vec3 rayDir, vec3 rayOrigin)
{
	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);

	// Calculate inverse of ray direction once.
	vec3 invRayDir = 1.0 / rayDir;

	// Store maximum extents of voxel volume.
	vec3 minEdge = inMinEdge;
	vec3 maxEdge = inMaxEdge;
	float bias = maxEdge.x / 1000000.0;

	// Only process ray if it intersects voxel volume.
	float tMin, tMax;
	vec3 result = rayAABBTest(rayOrigin, rayDir, minEdge, maxEdge);
	tMin = result.y;
	tMax = result.z;

	float depth = 1.0;

	if (result.x <= 0.0) {
		return false;
	}

	// Force initial ray position to start at the
	// camera origin if it is in the voxel box.
	tMin = max(0.0f, tMin);

	// Loop until ray exits volume.
	int itr = 0;
	while (tMin < tMax && ++itr < MAX_ITERATIONS) {
		vec3 pos = rayOrigin + rayDir * tMin;

		// Restart at top of tree.
		int offset = inOffset;

		// Which part of the space the voxel volume occupy.
		vec3 boxMin = inMinEdge;
		vec3 boxDim = inMaxEdge - inMinEdge;

		// Loop until a leaf or max subdivided node is found.
		bool hit = true;
		for (int i = 5; i > 0; i--) {

			uint node = uint(texelFetchBuffer(octree, offset).a);

			boxDim *= 0.5f;
			vec3 s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			uint select = uint(dot(s, vec3(4, 1, 2)));
			if ((node & (uint(1) << select)) == uint(0)) {
				hit = false;
				break;
			}

			if (i <= 1) {
				finalColor = vec4(mod(pos * 16, 1.0), 1.0);
				return true;
			}

			int bits = int(select + 1);
			uint toCount = bitfieldExtract(node, 0, bits);
			int address = int(bitCount(toCount));
			address += int(offset);

			offset = texelFetchBuffer(octree, address).a;
			if (offset == 0) {
				return true;
			}
		}

		// Update ray position to exit current node
		vec3 t0 = (boxMin - pos) * invRayDir;
		vec3 t1 = (boxMin + boxDim - pos) * invRayDir;
		vec3 tNext = max(t0, t1);
		tMin += min(tNext.x, min(tNext.y, tNext.z)) + bias;
	}

	if (itr == MAX_ITERATIONS) {
		finalColor = vec4(0, 1, 0, 1);
		return false;
	}

	return false;
}

void main(void)
{
	vec3 rayDir = normalize(inPosition - cameraPos);
	vec3 rayOrigin = inPosition;

	if (!trace(outColor, rayDir, rayOrigin)) {
		discard;
	}
}
`;
