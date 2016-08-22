// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.main;

import core.exception;

import watt.io;

import charge.ctl;
import charge.sys.resource;
import charge.core;
import charge.gfx;
import charge.game;
import charge.game.scene.background;
import charge.math.matrix;

import power.exp;
import power.viewer;


class Game : GameSceneManagerApp
{
public:
	this(string[] args)
	{
		// First init core.
		auto opts = new CoreOptions();
		opts.title = "Charged Power";
		opts.width = 800;
		opts.height = 600;
		super(opts);

		checkVersion();

		push(new Background(this, "res/tile.png", "res/logo.png"));
		push(new Scene(this));
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	void checkVersion()
	{
		// For texture functions.
		if (!GL_ARB_ES3_compatibility &&
		    !GL_ARB_texture_storage &&
		    !GL_VERSION_4_2) {
			throw new Exception("Need GL_ARB_texture_storage or OpenGL 4.2");
		}

		// For samplers functions.
		if (!GL_ARB_ES3_compatibility &&
		    !GL_ARB_sampler_objects &&
		    !GL_VERSION_3_3) {
			throw new Exception("Need GL_ARB_sampler_objects or OpenGL 3.3");
		}

/+
		// Works on mesa.
		// For shaders.
		if (!GL_ARB_ES2_compatibility ||
		    (!GL_ARB_gpu_shader5 &&
		     !GL_VERSION_4_5)) {
			throw new Exception("Need GL_ARB_gpu_shader5 or OpenGL 4.5");
		}
+/
	}
}

class Scene : GameSimpleScene
{
public:
	CtlInput input;
	GfxTexture bitmap;
	GfxDrawBuffer vbo;
	string str;

public:
	this(Game g)
	{
		super(g, Type.Menu);
		this.str = text;



		input = CtlInput.opCall();
		bitmap = GfxTexture2D.load(Pool.opCall(), "res/font.png");

		GfxBitmapState arg;
		arg.glyphWidth = cast(int)bitmap.width / 16;
		arg.glyphHeight = cast(int)bitmap.height / 16;
		arg.offX = 16;
		arg.offY = 16;
		auto b = new GfxDrawVertexBuilder(str.length);
		gfxBuildVertices(ref arg, b, cast(ubyte[])str);
		vbo = GfxDrawBuffer.make("power/scene", b);
	}

	override void close()
	{
		if (bitmap !is null) { bitmap.decRef(); bitmap = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void render(GfxTarget t)
	{
		Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(vbo.vao);

		bitmap.bind();
		glDrawArrays(GL_QUADS, 0, vbo.num);
		bitmap.unbind();

		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
		mManager.push(new Exp(mManager));
	}
}


enum string text =
"Lorem ipsum dolor sit amet,
consectetur adipiscing elit.
Donec in hendrerit est, non
volutpat nunc. In convallis,
metus vitae fringilla
porttitor, ex ante luctus
erat, non fringilla dui dolor
ac enim. Cum sociis natoque
penatibus et magnis dis
parturient montes, nascetur
ridiculus mus. Aliquam rhoncus
leo sed suscipit faucibus.
Quisque at risus eget neque
facilisis feugiat ac in tortor.
Nullam vitae purus nisl.";
