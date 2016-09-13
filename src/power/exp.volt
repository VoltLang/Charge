// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.exp;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;
import io = watt.io;

import charge.ctl;
import charge.sys.memory;
import charge.sys.resource;
import charge.core;
import charge.game;
import charge.gfx;

import math = charge.math;
import power.voxel;


class Exp : GameSimpleScene
{
public:
	CtlInput input;
	VoxelBuffer vbo;
	float rotation;
	GfxFramebuffer fbo;
	GfxDrawBuffer quad;
	GfxShader voxelShader;
	GfxShader aaShader;
	GLuint sampler;

	GfxTexture2D bitmap;
	GfxDrawBuffer textVbo;
	GfxDrawVertexBuilder textBuilder;
	GfxBitmapState textState;

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
		super(g, Type.Game);
		input = CtlInput.opCall();
		vb := new VoxelBuilder(3);
		vb.addCube(0.0f, 0.0f, 0.0f, math.Color4b.White);
		vb.addCube(1.0f, 1.0f, 1.0f, math.Color4b.White);
		vb.addCube(2.0f, 2.0f, 2.0f, math.Color4b.White);
		vbo = VoxelBuffer.make("voxels", vb);

		voxelShader = new GfxShader(voxelVertex450, voxelFragment450,
		                            null, null);
		aaShader = new GfxShader(aaVertex130, aaFragment130,
		                         ["position"], ["color", "depth"]);


		auto b = new GfxDrawVertexBuilder(4);
		b.add(-1.f, -1.f, -1.f, -1.f);
		b.add( 1.f, -1.f,  1.f, -1.f);
		b.add( 1.f,  1.f,  1.f,  1.f);
		b.add(-1.f,  1.f, -1.f,  1.f);
		quad = GfxDrawBuffer.make("power/exp/quad", b);

		glGenSamplers(1, &sampler);
		glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		bitmap = GfxTexture2D.load(Pool.opCall(), "res/font.png");

		textState.glyphWidth = cast(int)bitmap.width / 16;
		textState.glyphHeight = cast(int)bitmap.height / 16;
		textState.offX = 16;
		textState.offY = 16;

		text := "Info";
		textBuilder = new GfxDrawVertexBuilder(0);
		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo = GfxDrawBuffer.make("power/exp/text", textBuilder);

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
	}

	override void close()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (quad !is null) { quad.decRef(); quad = null; }
		if (bitmap !is null) { bitmap.decRef(); bitmap = null; }
		if (textVbo !is null) { textVbo.decRef(); textVbo = null; }
		if (sampler) { glDeleteSamplers(1, &sampler); sampler = 0; }
		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
		if (voxelShader !is null) {
			voxelShader.breakApart();
			voxelShader = null;
		}
		if (aaShader !is null) {
			aaShader.breakApart();
			aaShader = null;
		}
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void logic()
	{
		rotation += 0.01f;
	}

	override void render(GfxTarget t)
	{
		// If there is none or if t has a different size.
		setupFramebuffer(t);


		// Use the fbo
		t.unbind();
		fbo.bind();
		renderScene(fbo);
		fbo.unbind();
		t.bind();


		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		aaShader.bind();

		glBindVertexArray(quad.vao);
		fbo.color.bind();
		glBindSampler(0, sampler);

		glDrawArrays(GL_QUADS, 0, quad.num);

		glBindSampler(0, 0);
		fbo.color.unbind();
		glBindVertexArray(0);


		// Draw text
		updateText();
		math.Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(textVbo.vao);
		bitmap.bind();

		glDrawArrays(GL_QUADS, 0, textVbo.num);

		bitmap.unbind();
		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
	}

	void setupFramebuffer(GfxTarget t)
	{
		if (fbo !is null &&
		    (t.width * 2) == fbo.width &&
		    (t.height * 2) == fbo.height) {
			return;
		}

		if (fbo !is null) { fbo.decRef(); fbo = null; }
		fbo = GfxFramebuffer.make("power/exp/fbo", t.width * 2, t.height * 2);
	}

	void renderScene(GfxTarget t)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);


		rot := math.Quatf.opCall(rotation, 0.f, 0.f);
		vec := rot * math.Vector3f.opCall(0.f, 0.f, -2.f);
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

		// Setup vertex buffer.
		glCullFace(GL_BACK);
		glEnable(GL_CULL_FACE);
		glBindVertexArray(vbo.vao);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glDrawArrays(GL_QUADS, 0, vbo.num);
		glBindTexture(GL_TEXTURE_BUFFER, 0);
		glDisable(GL_CULL_FACE);
		glBindVertexArray(0);

		if (shouldEnd) {
			glEndQuery(GL_TIME_ELAPSED);
			queryInFlight = true;
		}

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);
	}

	void updateText()
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

		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo.update(textBuilder);
	}
}

enum string voxelVertex450 = `
#version 450 core

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec4 inColor;
layout (location = 0) out vec3 outPosition;

uniform mat4 matrix;


void main(void)
{
	outPosition = inPosition;
	gl_Position = matrix * vec4(inPosition, 1.0);
}
`;

enum string voxelFragment450 = `
#version 450 core
#define MAX_ITERATIONS	500

layout (location = 0) in vec3 inPosition;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;


vec3 rayAABBTest (vec3 rayOrigin, vec3 rayDir, vec3 aabbMin, vec3 aabbMax)
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

void main(void)
{
	vec4 finalColor = vec4(0.0);
	vec3 rayDir = inPosition - cameraPos; 
	vec3 rayOrigin = cameraPos; 

	rayDir = normalize(rayDir);

	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);
	
	// Calculate inverse of ray direction once.
	vec3 invRayDir = 1.0 / rayDir;
	
	// Store maximum extents of voxel volume.
	vec3 minEdge = vec3(0.0);
	vec3 maxEdge = vec3(1.0);
	float bias = maxEdge.x / 1000000.0;
	
	// Only process ray if it intersects voxel volume.
	float tMin, tMax;
	vec3 result = rayAABBTest(rayOrigin, rayDir, minEdge, maxEdge);	
	tMin = result.y;
	tMax = result.z;

	float depth = 1.0;
	bool hit = false;

	if (result.x > 0.0)
	{
		// Force initial ray position to start at the camera origin.
		tMin = max(0.0f, tMin);
	
		// Loop until ray exits volume.
		int itr = 0;
		while (tMin < tMax && ++itr < MAX_ITERATIONS)
		{
			vec3 pos = rayOrigin + rayDir * tMin;
			uint node = uint(texelFetchBuffer(octree, int(0)).a);
			vec3 boxMin = minEdge;
			vec3 boxDim = maxEdge - minEdge;
			
			// Loop until a leaf or max subdivided node is found.
			while ((node & uint(0xC0000000)) >> uint(30) == uint(0))
			{
				boxDim *= 0.5f;
				vec3 s = step(boxMin + boxDim, pos);
				boxMin = boxMin + boxDim * s;
				uint offset = (node & uint(0x3FFFFFFF)) + uint(dot(s, vec3(1, 2, 4)));
				node = uint(texelFetchBuffer(octree, int(offset)).a);
			}
			
			// If final node is a leaf, extract color and exit loop.
			if ((node & uint(0x80000000)) >> uint(31) == uint(1))
			{
				uint alpha = (node & uint(0x3F000000)) >> uint(24);
				uint red = (node & uint(0x00FF0000)) >> uint(16);
				uint green = (node & uint(0x0000FF00)) >> uint(8);
				uint blue = (node & uint(0x000000FF));
				
				alpha = alpha * uint(255) / uint(63);
				alpha /= uint(2);
				finalColor = vec4(red, green, blue, 255) / 255.0;
				
				// Record intersection depth point.
				vec3 t0 = (boxMin - rayOrigin) * invRayDir;
				vec3 t1 = (boxMin + boxDim - rayOrigin) * invRayDir;
				vec3 tIntersection = min(t0, t1);
				vec3 point = rayOrigin + rayDir * tIntersection;
				point = point / (maxEdge - minEdge);
				depth = clamp(point.z, 0.0, 1.0);

				hit = true;
				break;
			}

			// Update ray position to exit current node			
			vec3 t0 = (boxMin - pos) * invRayDir;
			vec3 t1 = (boxMin + boxDim - pos) * invRayDir;
			vec3 tNext = max(t0, t1);
			tMin += min(tNext.x, min(tNext.y, tNext.z)) + bias;
		}

		if (itr == MAX_ITERATIONS) {
			finalColor = vec4(0, 1, 0, 1);
		}
	}

	//if (!hit) {
	//	discard;
	//}

	outColor = finalColor;
}
`;

enum string aaVertex130 = `
#version 130

attribute vec2 position;

varying vec2 uvFS;


void main(void)
{
	uvFS = (position / 2 + 0.5);
	uvFS.y = 1 - uvFS.y;
	gl_Position = vec4(position, 0.0, 1.0);
}
`;

enum string aaFragment130 = `
#version 130

uniform sampler2D color;

varying vec2 uvFS;


void main(void)
{
	// Get color.
	vec4 c = texture(color, uvFS);

	gl_FragColor = vec4(c.xyz, 1.0);
}
`;
