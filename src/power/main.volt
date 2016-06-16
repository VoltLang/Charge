// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.main;

import watt.io;
import charge.ctl;
import charge.sys.resource;
import charge.core;
import charge.gfx;
import charge.game;
import charge.game.scene.background;
import charge.math.matrix;

import power.viewer;


class Game : GameSceneManagerApp
{
public:
	GfxFramebuffer fbo;
	GfxDrawBuffer vbo;
	GLuint sampler;



	this(string[] args)
	{
		// First init core.
		auto opts = new CoreOptions();
		opts.title = "Charged Power";
		opts.width = 800;
		opts.height = 600;
		super(opts);

		push(new Background(this, "res/tile.png", "res/logo.png"));
		push(new Scene(this));
		fbo = GfxFramebuffer.make("power/fbo", opts.width * 2, opts.height * 2);

		auto b = new GfxDrawVertexBuilder(4);
		b.add(0.0f, 0.0f, 0.0f, 0.0f);
		b.add(1.0f, 0.0f, 1.0f, 0.0f);
		b.add(1.0f, 1.0f, 1.0f, 1.0f);
		b.add(0.0f, 1.0f, 0.0f, 1.0f);
		vbo = GfxDrawBuffer.make("power/puff", b);

		glGenSamplers(1, &sampler);
		glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}

	override void close()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (sampler) { glDeleteSamplers(1, &sampler); sampler = 0; }
	}

	override void render(GfxTarget t)
	{
		fbo.bind();
		super.render(fbo);
		fbo.unbind();

		t.bind();

		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat, 1.0f, 1.0f);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glBindVertexArray(vbo.vao);

		fbo.tex.bind();
		glBindSampler(0, sampler);

		glDrawArrays(GL_QUADS, 0, vbo.num);

		glBindSampler(0, 0);
		fbo.tex.unbind();

		glBindVertexArray(0);
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
		mManager.push(new Viewer(mManager));
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
