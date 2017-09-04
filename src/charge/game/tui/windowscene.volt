// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Contains classes and code to create a text-user-interface window scene.
 */
module charge.game.tui.windowscene;

import watt.algorithm : max;

import math = charge.math;

import charge.gfx;
import charge.ctl;
import charge.game;

import tui = charge.game.tui;


/*!
 * A text-user-interface that draws to a single window on the screen.
 *
 * Usefull for implementing menus, see @ref charge.game.tui.menuscene.
 */
abstract class WindowScene : GameSimpleScene
{
public:
	enum HeaderExtra : u32 = 5;
	enum HeaderShadow : u32 = 2;
	enum BorderSize : u32 = 8;


public:
	posX, posY: i32;
	headerGrid: tui.Grid;
	grid: tui.Grid;

	headerBackgroundColor: math.Color4f;
	gridBackgroundColor: math.Color4f;


protected:
	mTarget: GfxFramebufferResizer;
	mBlitter: GfxTextureBlitter;


public:
	this(g: GameSceneManager, width: u32, height: u32)
	{
		super(g, Type.Menu);

		headerGrid = new tui.Grid(1, 1);
		headerGrid.setGlyphSize(cast(i32)GfxBitmapGlyphWidth*2, cast(i32)GfxBitmapGlyphHeight*2);
		grid = new tui.Grid(0, 0);
		grid.setGlyphSize(cast(i32)GfxBitmapGlyphWidth, cast(i32)GfxBitmapGlyphHeight);

		// Now that the grids are created, set the size.
		setSize(width, height);

		headerBackgroundColor = math.Color4f.from(0.f, 0.f, 1.f, 0.9f);
		gridBackgroundColor = math.Color4f.from(0.f, 0.f, 0.f, 0.6f);
	}


	/*
	 *
	 * Scene functions.
	 *
	 */

	override fn close()
	{
		mTarget.close();
		mBlitter.close();

		if (headerGrid !is null) {
			headerGrid.close();
			headerGrid = null;
		}
		if (grid !is null) {
			grid.close();
			grid = null;
		}
	}

	override fn mouseDown(m: CtlMouse, button: i32)
	{
		x, y: i32;
		getGridPositionOnScreen(out x, out y);
		x = m.x - x; y = m.y - y;

		if (x < 0 || y < 0) {
			return;
		}

		ux := cast(u32)x / GfxBitmapGlyphWidth;
		uy := cast(u32)y / GfxBitmapGlyphHeight;
		if (ux >= grid.width || uy >= grid.height) {
			return;
		}

		gridMouseDown(m, ux, uy, button);
	}

	override fn render(t: GfxTarget)
	{
		updateTarget(t);
		mBlitter.blit(t, mTarget.color, posX, posY);
	}


	/*
	 *
	 * Grid functions.
	 *
	 */

	fn gridMouseDown(m: CtlMouse, x: u32, y: u32, button: i32) { }


	/*
	 *
	 * Getters and setter.
	 *
	 */

	fn setSize(width: u32, height: u32)
	{
		// Make width be even.
		width += width & 0x1;

		grid.setSize(width, height);
	}

	fn setHeader(glyphs: scope const(u8)[])
	{
		headerGrid.setSize(cast(u32)glyphs.length, 1);
		foreach (i, glyph; glyphs) {
			headerGrid.put(cast(i32)i, 0, glyph);
		}
	}

	fn getSizeInPixels(out width: u32, out height: u32)
	{
		headerWidth, headerHeight: u32;
		headerGrid.getSizeInPixels(out headerWidth, out headerHeight);

		gridWidth, gridHeight: u32;
		grid.getSizeInPixels(out gridWidth, out gridHeight);

		headerHeight += HeaderExtra * 2; // Add extra pixels at top.

		width = max(headerWidth, gridWidth) + BorderSize * 2;
		height = gridHeight + headerHeight + BorderSize * 2 + BorderSize;
	}

	fn getGridPositionOnScreen(out x: i32, out y: i32)
	{
		headerWidth, headerHeight: u32;
		getHeaderSizeInPixels(out headerWidth, out headerHeight);

		x = posX + cast(i32)(BorderSize);
		y = posY + cast(i32)(headerHeight + BorderSize + BorderSize);
	}

	fn getHeaderSizeInPixels(out w: u32, out h: u32)
	{
		headerGrid.getSizeInPixels(out w, out h);
		h += HeaderExtra * 2; // Add extra pixels at top.
	}


private:
	fn updateTarget(t: GfxTarget)
	{
		if (!grid.isDirty && !headerGrid.isDirty && mTarget.fbo !is null) {
			return;
		}

		// Setup the rendering state.
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		// Get the total size of the window.
		totalWidth, totalHeight: u32;
		getSizeInPixels(out totalWidth, out totalHeight);

		// Figure out where the header is drawn.
		headerWidth, headerHeight: u32;
		getHeaderSizeInPixels(out headerWidth, out headerHeight);

		headerBoxX := cast(GLint)(BorderSize);
		headerBoxY := cast(GLint)(BorderSize);
		headerBoxW := cast(GLsizei)(totalWidth - BorderSize * 2);
		headerBoxH := cast(GLsizei)(headerHeight);
		headerX := cast(i32)((totalWidth - BorderSize * 2) / 2 - headerWidth / 2 + BorderSize);
		headerY := headerBoxY + cast(i32)HeaderExtra;
		headerShadowX := headerX + cast(i32)HeaderShadow;
		headerShadowY := headerY + cast(i32)HeaderShadow;

		gridX := cast(i32)(BorderSize);
		gridY := cast(i32)(headerHeight + BorderSize + BorderSize);

		// Setup the target.
		mTarget.bind(t, totalWidth, totalHeight);

		// Clear the target, use scissor to color
		// the header a different color.
		glClearColor(
			gridBackgroundColor.r,
			gridBackgroundColor.g,
			gridBackgroundColor.b,
			gridBackgroundColor.a);
		glClear(GL_COLOR_BUFFER_BIT);
		glScissor(headerBoxX, headerBoxY, headerBoxW, headerBoxH);
		glEnable(GL_SCISSOR_TEST);
		glClearColor(
			headerBackgroundColor.r,
			headerBackgroundColor.g,
			headerBackgroundColor.b,
			headerBackgroundColor.a);
		glClear(GL_COLOR_BUFFER_BIT);
		glDisable(GL_SCISSOR_TEST);

		// Draw the header.
		glBindSampler(0, gfxDrawSamplerNearest);
		headerGrid.setOffset(headerShadowX, headerShadowY);
		headerGrid.setColor(math.Color4b.Black);
		headerGrid.draw(mTarget.fbo);
		headerGrid.setOffset(headerX, headerY);
		headerGrid.setColor(math.Color4b.White);
		headerGrid.draw(mTarget.fbo);

		// Draw the main grid.
		grid.setOffset(gridX+1, gridY+1);
		grid.setColor(math.Color4b.Black);
		grid.draw(mTarget.fbo);
		grid.setOffset(gridX, gridY);
		grid.setColor(math.Color4b.White);
		grid.draw(mTarget.fbo);

		// Clean state.
		glBindSampler(0, 0);
		glDisable(GL_BLEND);
		mTarget.unbind(t);
	}
}
