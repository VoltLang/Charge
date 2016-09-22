// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.viewer;

import watt.math;
import io = watt.io;

import charge.ctl;
import charge.sys.memory;
import charge.sys.resource;
import charge.core;
import charge.game;
import charge.gfx;

import math = charge.math;

import power.voxel.boxel;
import power.voxel.magica;


class Viewer : GameSimpleScene
{
public:
	CtlInput input;
	BoxelBuffer vbo;
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
		vbo = loadFile("res/test.vox");

		voxelShader = new GfxShader(voxelVertexES, voxelFragmentES,
		                            ["position", "color"], null);
		aaShader = new GfxShader(aaVertex130, aaFragment130,
		                         ["position"], ["color", "depth"]);


		auto b = new GfxDrawVertexBuilder(4);
		b.add(-1.f, -1.f, -1.f, -1.f);
		b.add( 1.f, -1.f,  1.f, -1.f);
		b.add( 1.f,  1.f,  1.f,  1.f);
		b.add(-1.f,  1.f, -1.f,  1.f);
		quad = GfxDrawBuffer.make("power/quad", b);

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
		fbo = GfxFramebuffer.make("power/fbo", t.width * 2, t.height * 2);
	}

	void renderScene(GfxTarget t)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);


		rot := math.Quatf.opCall(rotation, 0.f, 0.f);
		vec := rot * math.Vector3f.opCall(0.f, 0.f, -32.f);
		pos := math.Point3f.opCall(16.f, 8.f, 16.f) - vec;


		math.Matrix4x4f view;
		view.setToLookFrom(ref pos, ref rot);

		math.Matrix4x4f proj;
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 256.f);
		proj.setToMultiply(ref view);


		// Setup shader.
		voxelShader.bind();
		voxelShader.matrix4("matrix", 1, true, proj.ptr);

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

varying vec4 colorFs;

void main(void)
{
	colorFs = color;
	gl_Position = matrix * vec4(position, 1.0);
}
`;

enum string voxelFragmentES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

varying vec4 colorFs;

void main(void)
{
	gl_FragColor = colorFs;
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

float doTest(vec4 a)
{
	return float(any(notEqual(a, a.yzwx)));
}

void main(void)
{
	// Get color.
	vec4 c = texture(color, uvFS);

	vec4 s1 = textureGatherOffset(color, uvFS, ivec2(0,  1), 3);
	vec4 s2 = textureGatherOffset(color, uvFS, ivec2(0, -1), 3);
	vec4 s3 = textureGatherOffset(color, uvFS, ivec2( 1, 0), 3);
	vec4 s4 = textureGatherOffset(color, uvFS, ivec2(-1, 0), 3);

	// textureGather(color, uvFS, 3);
	vec4 a = vec4(s1.wz, s2.yx);

	float factor = doTest(a) * .4 +
		doTest(s1) * .3 +
		doTest(s2) * .3 +
		doTest(s3) * .3 +
		doTest(s4) * .3;

	gl_FragColor = mix(c, vec4(0, 0, 0, 1), factor);
}
`;
