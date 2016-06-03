// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.viewer;

import io = watt.io;
import charge.ctl;
import charge.sys.resource;
import charge.core;
import charge.gfx.target;
import charge.game;
import charge.game.scene.background;
import charge.gfx.gl;
import charge.gfx.shader;
import charge.gfx.texture;
import charge.gfx.bitmapfont;
import charge.math.quat;
import charge.math.point;
import charge.math.matrix;

import draw = charge.gfx.draw;


class Viewer : GameScene
{
public:
	CtlInput input;
	Texture bitmap;
	draw.Buffer vbo;
	float rotation;
	Point3f pos;


public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		input = CtlInput.opCall();

		pos.x = 0.f;
		pos.z = 3.f;
	}

	override void close()
	{
		if (bitmap !is null) { bitmap.decRef(); bitmap = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
	}


	/*
	 *
	 * Our own methods and helpers.
	 *
	 */

	void down(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
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

	override void render(Target t)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
		glUseProgram(0);


		Quatf rot = Quatf.opCall(rotation, 0.f, 0.f);

		Matrix4x4f view;
		view.setToLookFrom(ref pos, ref rot);

		Matrix4x4f proj;
		proj.setToPerspective(45.f, 800.f / 600.f, 0.1f, 50.f);
		proj.setToMultiply(ref view);

		// Use this shader for now.
		draw.shader.bind();
		draw.shader.matrix4("matrix", 1, true, proj.ptr);

		// We are lazy
		glBindVertexArray(0);
		glBegin(GL_QUADS);
		glVertex3i(-1,  1, 0);
		glVertex3i(-1, -1, 0);
		glVertex3i(1,  -1, 0);
		glVertex3i(1,   1, 0);
		glEnd();
	}

	override void assumeControl()
	{
		input.keyboard.down = down;
	}

	override void dropControl()
	{
		if (input.keyboard.down is down) {
			input.keyboard.down = null;
		}
	}
}
