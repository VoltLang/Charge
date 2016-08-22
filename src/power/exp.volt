// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.exp;

import watt.math;
import watt.io.file;
import watt.algorithm;
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

		voxelShader = new GfxShader(voxelVertexES, voxelFragmentES,
		                            ["position", "color"], null);
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
	}

	override void close()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (quad !is null) { quad.decRef(); quad = null; }
		if (sampler) { glDeleteSamplers(1, &sampler); sampler = 0; }
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
		vec := rot * math.Vector3f.opCall(0.f, 0.f, -4.f);
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

		// Setup shader.
		glBindVertexArray(vbo.vao);
		glDrawArrays(GL_QUADS, 0, vbo.num);
		glBindVertexArray(0);

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);
	}
}


enum string voxelVertexES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute vec3 position;
attribute vec4 color;

uniform mat4 matrix;

varying vec3 posFs;

void main(void)
{
	posFs = position;
	gl_Position = matrix * vec4(position, 1.0);
}
`;

enum string voxelFragmentES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

uniform vec3 cameraPos;

varying vec3 posFs;

vec4 getColor()
{
	vec3 direction = normalize(posFs - cameraPos);
	vec3 center = vec3(0.5, 0.5, 0.5);
	vec3 origin = cameraPos;
	float r = 0.5;

//	float len = dot(direction, center - origin);
//	if (len < 0.0) {
//		return vec4(0.0, 0.0, 0.0, 1.0);
//	}
//	return vec4(1.0, 1.0, 1.0, 1.0);

	float a = 1.0;//dot(direction, direction);
	float b = 2.0 * dot(direction, origin - center);
	float c = dot(center, center) + dot(origin, origin) - 2.0 * dot(center, origin) - r*r;
	float test = b*b - 4.0*a*c;

	if (test >= 0.0) {
		float u = (-b - sqrt(test)) / (2.0 * a);
		vec3 hitp = origin + u * direction;
		return vec4(hitp, 1.0);
	}
	return vec4(0.0, 0.0, 0.0, 1.0);
}

void main(void)
{
	gl_FragColor = getColor();

	//}

	//float test = b*b - 4.0*a*c;

	//if (test >= 0.0) {
	//}
	//vec3 p = vec3(cameraPos.x, 0.0f, cameraPos.z);//normalize(posFs + cameraPos);

	//float x = (posFs.x - cameraPos.x) + 0.5;
	//float y = (posFs.y - cameraPos.y) + 0.5;
	//gl_FragColor = vec4(x, x, x, 1.0);
}
`;

enum string aaVertex130 = `
#version 130
#extension GL_ARB_gpu_shader5 : require

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
#extension GL_ARB_gpu_shader5 : require

uniform sampler2D color;

varying vec2 uvFS;


void main(void)
{
	// Get color.
	vec4 c = texture(color, uvFS);

	gl_FragColor = vec4(c.xyz, 1.0);
}
`;
