// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.main;

import watt.io;
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
import charge.math.matrix;

import draw = charge.gfx.draw;

import power.viewer;


class Game : GameSceneManagerApp
{
public:
	Framebuffer fbo;
	draw.Buffer vbo;
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
		fbo = Framebuffer.make("power/fbo", opts.width * 2, opts.height * 2);

		auto b = new draw.VertexBuilder(4);
		b.add(0.0f, 0.0f, 0.0f, 0.0f);
		b.add(1.0f, 0.0f, 1.0f, 0.0f);
		b.add(1.0f, 1.0f, 1.0f, 1.0f);
		b.add(0.0f, 1.0f, 0.0f, 1.0f);
		vbo = draw.Buffer.make("power/puff", b);

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

	override void render(Target t)
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

		draw.shader.bind();
		draw.shader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glBindVertexArray(vbo.vao);

		fbo.tex.bind();
		glBindSampler(0, sampler);

		glDrawArrays(GL_QUADS, 0, vbo.num);

		glBindSampler(0, 0);
		fbo.tex.unbind();

		glBindVertexArray(0);
	}
}

class Scene : GameScene
{
public:
	CtlInput input;
	Texture bitmap;
	draw.Buffer vbo;
	string str;

public:
	this(Game g)
	{
		super(g, Type.Menu);
		this.str = text;

		input = CtlInput.opCall();
		bitmap = Texture2D.load(Pool.opCall(), "res/font.png");

		BitmapState arg;
		arg.glyphWidth = cast(int)bitmap.width / 16;
		arg.glyphHeight = cast(int)bitmap.height / 16;
		arg.offX = 16;
		arg.offY = 16;
		auto b = new draw.VertexBuilder(str.length);
		buildVertices(ref arg, b, cast(ubyte[])str);
		vbo = draw.Buffer.make("power/scene", b);
	}

	override void close()
	{
		if (bitmap !is null) { bitmap.decRef(); bitmap = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	void down(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
		mManager.push(new Viewer(mManager));
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void logic() {}

	override void render(Target t)
	{
		Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);

		draw.shader.bind();
		draw.shader.matrix4("matrix", 1, true, mat.u.a.ptr);

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
