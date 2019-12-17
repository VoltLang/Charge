// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module charge.game.scene.background;

import lib.gl.gl33;

import sys = charge.sys;
import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;
import charge.game.scene.scene;


class Background : Scene
{
protected:
	mBuf: GLuint;
	mVao: GLuint;
	mNum: GLsizei;

	mWidth: uint;
	mHeight: uint;

	mLogo: gfx.Texture;
	mLogoWidth: uint;
	mLogoHeight: uint;
	mTile: gfx.Texture;
	mTileWidth: uint;
	mTileHeight: uint;


public:
	this(m: Manager)
	{
		super(m, Type.Background);
	}

	fn setTile(filename: string)
	{
		if (filename is null) {
			setTile(cast(sys.File)null);
			return;
		}

		if (file := sys.File.load(filename)) {
			setTile(file);
		}
	}

	fn setTile(file: sys.File)
	{
		gfx.reference(ref mTile, null);

		if (file !is null) {
			mTile = gfx.Texture2D.load(file);
		}
	}

	fn setLogo(filename: string)
	{
		if (filename is null) {
			setTile(cast(sys.File)null);
			return;
		}

		if (file := sys.File.load(filename)) {
			setLogo(file);
		}
	}

	fn setLogo(file: sys.File)
	{
		gfx.reference(ref mLogo, null);

		if (file !is null) {
			mLogo = gfx.Texture2D.load(file);
		}
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	fn initBuffers(t: gfx.Target)
	{
		if (mTile is null && mLogo is null) {
			return;
		}

		tW, tH, lW, lH: uint;
		if (mTile !is null) { tW = mTile.width; tH = mTile.height; }
		if (mLogo !is null) { lW = mLogo.width; lH = mLogo.height; }

		if (t.width == mWidth && t.height == mHeight &&
		    tW == mTileWidth && tH == mTileHeight &&
		    lW == mLogoWidth && lH == mLogoHeight) {
			return;
		}
		mWidth = t.width; mHeight = t.height;
		mTileWidth = tW; mTileHeight = tH;
		mLogoWidth = lW; mLogoHeight = lH;

		b := new gfx.DrawVertexBuilder(8);

		// Tile vertecies
		if (mTile !is null) {
			factor: uint;
			tileWidth: uint;
			tileHeight: uint;
			while (tileWidth < t.width || tileHeight < t.height) {
				factor += 2;
				tileWidth = mTile.width * factor;
				tileHeight = mTile.height * factor;
			}

			tX1 := cast(f32)(t.width / 2) - cast(f32)(tileWidth / 2);
			tY1 := cast(f32)(t.height / 2) - cast(f32)(tileHeight / 2);

			tX2 := tX1 + cast(f32)tileWidth;
			tY2 := tY1 + cast(f32)tileHeight;
			f := cast(f32)factor;

			b.add(tX1, tY1, 0.0f, 0.0f);
			b.add(tX2, tY1,    f, 0.0f);
			b.add(tX1, tY2, 0.0f,    f);
			b.add(tX2, tY2,    f,    f);
		}

		// Logo vertecies
		if (mLogo !is null) {
			logoWidth := mLogo.width;
			logoHeight := mLogo.height;
			while (logoWidth > t.width || logoHeight > t.height) {
				logoWidth /= 2;
				logoHeight /= 2;
			}

			lX1 := cast(f32)(t.width / 2 - logoWidth / 2);
			lY1 := cast(f32)(t.height / 2 - logoHeight / 2);
			lX2 := lX1 + cast(f32)logoWidth;
			lY2 := lY1 + cast(f32)logoHeight;

			b.add(lX1, lY1, 0.0f, 0.0f);
			b.add(lX2, lY1, 1.0f, 0.0f);
			b.add(lX1, lY2, 0.0f, 1.0f);
			b.add(lX2, lY2, 1.0f, 1.0f);
		}

		if (mBuf) { glDeleteBuffers(1, &mBuf); mBuf = 0; }
		if (mVao) { glDeleteVertexArrays(1, &mVao); mVao = 0; }

		b.bake(out mVao, out mBuf, out mNum);
		gfx.destroy(ref b);
	}

	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		gfx.reference(ref mTile, null);
		gfx.reference(ref mLogo, null);
		if (mBuf) { glDeleteBuffers(1, &mBuf); mBuf = 0; }
		if (mVao) { glDeleteVertexArrays(1, &mVao); mVao = 0; }
	}

	override fn updateActions(timepoint: i64)
	{

	}

	override fn logic()
	{

	}

	override fn render(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		initBuffers(t);

		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		if (mTile is null && mLogo is null) {
			return;
		}

		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);
		gfx.drawShader.bind();
		gfx.drawShader.matrix4("matrix", 1, true, ref mat);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(mVao);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

		offset: GLint;
		if (mTile !is null) {
			mTile.bind();
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			mTile.unbind();
			offset += 4;
		}

		if (mLogo !is null) {
			mLogo.bind();
			glDrawArrays(GL_TRIANGLE_STRIP, offset, 4);
			mLogo.unbind();
		}

		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override fn assumeControl() {}
	override fn dropControl() {}
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
