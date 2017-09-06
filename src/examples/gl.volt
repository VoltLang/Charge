// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module examples.gl;

import core.exception;

import ctl = charge.ctl;
import gfx = charge.gfx;
import math = charge.math;
import game = charge.game;

import charge.core;
import charge.gfx.gl;


class Game : game.SceneManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new CoreOptions();
		super(opts);

		s := new Scene(this, opts.width, opts.height);
		push(s);
	}
}


class Scene : game.SimpleScene
{
public:
	input: ctl.Input;
	tex: gfx.Texture;
	buf: gfx.DrawBuffer;
	width: uint;
	height: uint;

public:
	this(Game g, uint width, uint height)
	{
		super(g, Type.Game);
		this.width = width;
		this.height = height;

		input = ctl.Input.opCall();

		checkVersion();

		tex = gfx.Texture2D.load("res/logo.png");

		initBuffers();
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	fn checkVersion()
	{
		// For texture functions.
		if (!GL_VERSION_4_5) {
			throw new Exception("OpenGL features missing");
		}

		// For shaders.
		if (!GL_ARB_ES2_compatibility &&
		    !GL_VERSION_4_5) {
			throw new Exception("Need GL_ARB_ES2_compatibility or OpenGL 4.5");
		}
	}

	fn initBuffers()
	{
		texWidth := tex.width;
		texHeight := tex.height;
		while (texWidth > width || texHeight > height) {
			texWidth /= 2;
			texHeight /= 2;
		}

		x := width / 2 - texWidth / 2;
		y := height / 2 - texHeight / 2;

		fX := cast(float)x;
		fY := cast(float)y;
		fXW := cast(float)(x + texWidth);
		fYH := cast(float)(y + texHeight);

		b := new gfx.DrawVertexBuilder(6);
		b.add(fX,  fY,  0.0f, 0.0f);
		b.add(fXW, fY,  1.0f, 0.0f);
		b.add(fXW, fYH, 1.0f, 1.0f);
		b.add(fXW, fYH, 1.0f, 1.0f);
		b.add(fX,  fYH, 0.0f, 1.0f);
		b.add(fX,  fY,  0.0f, 0.0f);
		buf = gfx.DrawBuffer.make("example/gl/buffer", b);
		gfx.destroy(ref b);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		gfx.reference(ref tex, null);
		gfx.reference(ref buf, null);
	}

	override fn render(t: gfx.Target)
	{
		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);

		gfx.drawShader.bind();
		gfx.drawShader.matrix4("matrix", 1, true, ref mat);

		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(buf.vao);
		tex.bind();

		// Draw the triangle.
		glDrawArrays(GL_TRIANGLES, 0, buf.num);

		tex.unbind();
		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override fn keyDown(ctl.Keyboard, int)
	{
		mManager.closeMe(this);
	}
}

enum string vertexShader450 = `
#version 450 core

layout (location = 0) in vec2 inPosition;
layout (location = 1) in vec2 inUv;
layout (location = 2) in vec4 inColor;

layout (location = 0) out vec2 outUv;
layout (location = 1) out vec4 outColor;

uniform mat4 matrix;

void main(void)
{
	outUv = inUv;
	outColor = inColor;
	gl_Position = matrix * vec4(inPosition, 0.0, 1.0);
}
`;

enum string fragmentShader450 = `
#version 450 core

layout (location = 0) out vec4 outColor;

layout (location = 0) in vec2 inUv;
layout (location = 1) in vec4 inColor;

layout (binding = 0) uniform sampler2D tex;

void main(void)
{
	outColor = texture(tex, inUv) * inColor;
}
`;

enum string vertexShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 position;
attribute vec2 uv;
attribute vec4 color;

uniform mat4 matrix;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	uvFs = uv;
	colorFs = color;
	gl_Position = matrix * vec4(position, 0.0, 1.0);
}
`;

enum string fragmentShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 tx;
uniform sampler2D tex;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	vec4 t = texture2D(tex, uvFs);
	gl_FragColor = t * colorFs;
}
`;
