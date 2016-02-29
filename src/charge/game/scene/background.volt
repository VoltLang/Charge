// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.game.scene.background;

import charge.game.scene.scene;
import charge.gfx.gl;
import draw = charge.gfx.draw;
import charge.gfx.shader;
import charge.gfx.target;
import charge.gfx.texture;
import charge.math.matrix;
import charge.sys.resource;

import watt.io;

class Background : Scene
{
public:
	Texture tile;
	Texture logo;
	GLuint buf;
	GLuint vao;
	uint width;
	uint height;

public:
	this(SceneManager sm, uint width, uint height
	     string tileName, string logoName)
	{
		super(sm, Type.Background);
		this.width = width;
		this.height = height;

		if (tileName !is null) {
			tile = Texture2D.load(Pool.opCall(), tileName);
		}
		if (logoName !is null) {
			logo = Texture2D.load(Pool.opCall(), logoName);
		}

		initShaders();

		initBuffers();
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	void initShaders()
	{

	}

	void initBuffers()
	{
		if (tile is null && logo is null) {
			return;
		}

		auto b = new draw.VertexBuilder(8);

		// Tile vertecies
		if (tile !is null) {
			uint factor;
			uint tileWidth;
			uint tileHeight;
			while (tileWidth < width || tileHeight < height) {
				factor += 2;
				tileWidth = tile.width * factor;
				tileHeight = tile.height * factor;
			}

			float tX1 = cast(float)(width / 2) - cast(float)(tileWidth / 2);
			float tY1 = cast(float)(height / 2) - cast(float)(tileHeight / 2);

			float tX2 = tX1 + cast(float)tileWidth;
			float tY2 = tY1 + cast(float)tileHeight;
			float f = cast(float)factor;

			b.add(tX1, tY1, 0.0f, 0.0f);
			b.add(tX2, tY1,    f, 0.0f);
			b.add(tX2, tY2,    f,    f);
			b.add(tX1, tY2, 0.0f,    f);
		}

		// Logo vertecies
		if (logo !is null) {
			uint logoWidth = logo.width;
			uint logoHeight = logo.height;
			while (logoWidth > width || logoHeight > height) {
				logoWidth /= 2;
				logoHeight /= 2;
			}

			float lX1 = cast(float)(width / 2 - logoWidth / 2);
			float lY1 = cast(float)(height / 2 - logoHeight / 2);
			float lX2 = lX1 + cast(float)logoWidth;
			float lY2 = lY1 + cast(float)logoHeight;

			b.add(lX1, lY1, 0.0f, 0.0f);
			b.add(lX2, lY1, 1.0f, 0.0f);
			b.add(lX2, lY2, 1.0f, 1.0f);
			b.add(lX1, lY2, 0.0f, 1.0f);
		}

		b.bake(out vao, out buf);
		b.close();
	}

	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close()
	{
		if (tile !is null) { tile.decRef(); tile = null; }
		if (logo !is null) { logo.decRef(); logo = null; }
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
		if (vao) { glDeleteVertexArrays(1, &vao); vao = 0; }
	}

	override void logic()
	{

	}

	override void render(Target t)
	{
		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		if (tile is null && logo is null) {
			return;
		}

		Matrix4x4f mat;
		mat.setToOrtho(0.0f, cast(float)width, cast(float)height, 0.0f, -1.0f, 1.0f);
		draw.shader.bind();
		draw.shader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(vao);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

		GLint offset;
		if (tile !is null) {
			tile.bind();
			glDrawArrays(GL_QUADS, 0, 4);
			tile.unbind();
			offset += 4;
		}

		if (logo !is null) {
			logo.bind();
			glDrawArrays(GL_QUADS, offset, 4);
			logo.unbind();
		}

		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void assumeControl() {}
	override void dropControl() {}
}

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
