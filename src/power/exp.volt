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
	}

	override void close()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (quad !is null) { quad.decRef(); quad = null; }
		if (bitmap !is null) { bitmap.decRef(); bitmap = null; }
		if (textVbo !is null) { textVbo.decRef(); textVbo = null; }
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

	void updateText()
	{
		str := `Info:
Rotation: %s`;

		text := format(str, cast(double)rotation);

		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo.update(textBuilder);
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

vec4 getColor(vec3 center, float r)
{
	vec3 direction = posFs - cameraPos;
	vec3 origin = cameraPos;

	float a = dot(direction, direction);
	float b = 2.0 * dot(direction, origin - center);
	float c = dot(center, center) + dot(origin, origin) - 2.0 * dot(center, origin) - r*r;
	float test = b*b - 4.0*a*c;

	if (test >= 0.0) {
		float u = (-b - sqrt(test)) / (2.0 * a);
		vec3 hitp = origin + u * direction;
		return vec4(hitp, 1.0);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

void main(void)
{
	vec4 c1 = getColor(vec3(1.5, 0.5, 1.5), 0.5);
	vec4 c2 = getColor(vec3(0.5, 1.0, 0.5), 0.5);

	if (c1.w == 1.0) {
		gl_FragColor = c1;
	} else {
		gl_FragColor = c2;
	}
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
