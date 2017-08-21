// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.game.tui.grid;

import math = charge.math;

import charge.gfx.gl;
import charge.gfx.draw;
import charge.gfx.target;
import charge.gfx.bitmapfont;


/*!
 * A glyph grid that you can use to create text-user-interface with.
 */
final class Grid
{
protected:
	mData: u8[];
	mTextVBO: DrawBuffer;
	mTextState: BitmapState;
	mTextBuilder: DrawVertexBuilder;
	mWidth, mHeight: u32;
	mColor: math.Color4b;
	mDirty: bool;


public:
	this(width: u32, height: u32)
	{
		setSize(width, height);
		setGlyphSize(GlyphWidth, GlyphHeight);
		setOffset(0, 0);

		mTextBuilder = new DrawVertexBuilder(0);
		mTextBuilder.reset(mData.length * 6u);
		mTextState.buildVerticesGrid(mTextBuilder, mWidth, mData, mColor);
		mTextVBO = DrawBuffer.make("power/exp/text", mTextBuilder);
	}

	fn close()
	{
		if (mTextVBO !is null) { mTextVBO.decRef(); mTextVBO = null; }
		if (mTextBuilder !is null) { mTextBuilder = null; }
	}

	fn put(x: i32, y: i32, glyph: u8)
	{
		if (x < 0 || y < 0 ||
		    cast(u32)x >= mWidth ||
		    cast(u32)y >= mHeight) {
			return;
		}

		mData[cast(u32)x + cast(u32)y * mWidth] = glyph;
		mDirty = true;
	}

	fn setSize(width: u32, height: u32)
	{
		if (mWidth == width && mHeight == height) {
			return reset();
		}

		mWidth = width;
		mHeight = height;
		mData = new u8[](width * height);
		reset();
	}

	fn setGlyphSize(width: i32, height: i32)
	{
		if (mTextState.glyphWidth == width && mTextState.glyphHeight == height) {
			return;
		}
		mDirty = true;
		mTextState.glyphWidth = width;
		mTextState.glyphHeight = height;
	}

	fn setOffset(x: i32, y: i32)
	{
		if (mTextState.offX == x && mTextState.offY == y) {
			return;
		}
		mDirty = true;
		mTextState.offX = x;
		mTextState.offY = y;
	}

	fn setColor(color: math.Color4b)
	{
		if (mColor == color) {
			return;
		}

		mColor = color;
		mDirty = true;
	}

	fn reset()
	{
		count: u32;
		foreach (i; 0 .. mHeight) {
			foreach (j; 0 .. mWidth) {
				mData[count++] = 0;
			}
		}
	}

	fn getSizeInPixels(out width: u32, out height: u32)
	{
		width = cast(u32)mTextState.glyphWidth * this.mWidth;
		height = cast(u32)mTextState.glyphHeight * this.mHeight;
	}

	fn draw(t: Target)
	{
		updateVBO();

		// Draw text
		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);

		drawShader.bind();
		drawShader.matrix4("matrix", 1, true, ref mat);

		glBindVertexArray(mTextVBO.vao);
		bitmapTexture.bind();

		glDrawArrays(GL_TRIANGLES, 0, mTextVBO.num);

		bitmapTexture.unbind();
		glBindVertexArray(0);
	}

	@property fn isDirty() bool { return mDirty; }


protected:
	fn updateVBO()
	{
		if (!mDirty) {
			return;
		}

		mTextState = mTextState;
		mDirty = false;
		mTextBuilder.reset(mData.length * 6u);
		mTextState.buildVerticesGrid(mTextBuilder, mWidth, mData, mColor);
		mTextVBO.update(mTextBuilder);
	}
}
