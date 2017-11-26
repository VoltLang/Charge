// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module examples.gl;

import core.exception;

import core = charge.core;
import ctl = charge.ctl;
import gfx = charge.gfx;
import math = charge.math;
import scene = charge.game.scene;

import charge.gfx.gl;


class Game : scene.ManagerApp
{
public:
	this(args: string[])
	{
		// First init core.
		opts := new core.Options();
		super(opts);

		s := new Scene(this, opts.width, opts.height);
		push(s);
	}
}


class Scene : scene.Simple
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
