// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Contains classes and code to create a text-user-interface menu.
 */
module charge.game.scene.tuimenu;

import math = charge.math;

import charge.gfx.gl;
import charge.gfx.draw;
import charge.gfx.target;
import charge.gfx.helpers;
import charge.gfx.texture;
import charge.gfx.bitmapfont;
import charge.ctl.mouse;
import charge.ctl.keyboard;
import charge.math.matrix;
import charge.game.scene.scene;
import charge.game.scene.simple;

import tui = charge.game.tui;


/*!
 * A text-user-interface that draws to a single window on the screen.
 *
 * Usefull for implementing menus.
 */
class TuiWindowScene : SimpleScene
{
public:
	enum HeaderExtra : u32 = 3;
	enum HeaderShadow : u32 = 2;
	enum BorderSize : u32 = 8;


public:
	posX, posY: i32;
	headerGrid: tui.Grid;
	grid: tui.Grid;

	headerBackgroundColor: math.Color4f;
	gridBackgroundColor: math.Color4f;


protected:
	mTarget: FramebufferResizer;
	mBlitter: TextureBlitter;


public:
	this(g: SceneManager, width: u32, height: u32)
	{
		super(g, Type.Menu);
		headerGrid = new tui.Grid(0, 0);
		headerGrid.setGlyphSize(cast(i32)GlyphWidth*2, cast(i32)GlyphHeight*2);
		grid = new tui.Grid(0, 0);
		grid.setGlyphSize(cast(i32)GlyphWidth, cast(i32)GlyphHeight);

		// Now that the grids are created, set the size.
		setSize(width, height);

		headerBackgroundColor = math.Color4f.from(0.f, 0.f, 1.f, 0.9f);
		gridBackgroundColor = math.Color4f.from(0.f, 0.f, 0.f, 0.6f);
	}

	fn setSize(width: u32, height: u32)
	{
		// Make width be even.
		width += width & 0x1;

		grid.setSize(width, height);
		headerGrid.setSize(width / 2, 1);
	}

	fn getSizeInPixels(out width: u32, out height: u32)
	{
		headerWidth, headerHeight: u32;
		headerGrid.getSizeInPixels(out headerWidth, out headerHeight);

		gridWidth, gridHeight: u32;
		grid.getSizeInPixels(out gridWidth, out gridHeight);

		headerHeight += HeaderExtra; // Add extra pixels at top.

		width = gridWidth + BorderSize * 2;
		height = gridHeight + headerHeight + BorderSize * 2 + BorderSize;
	}

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

	override fn render(t: Target)
	{
		updateTarget(t);
		mBlitter.blit(t, mTarget.color, posX, posY);
	}


private:
	fn updateTarget(t: Target)
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
		headerGrid.getSizeInPixels(out headerWidth, out headerHeight);
		headerHeight += HeaderExtra; // Add extra pixels at top.

		headerBoxX := cast(i32)(BorderSize);
		headerBoxY := cast(i32)(BorderSize);
		headerX := headerBoxX;
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
		glScissor(cast(GLint)BorderSize, cast(GLint)BorderSize,
		          cast(GLsizei)headerWidth, cast(GLsizei)headerHeight);
		glEnable(GL_SCISSOR_TEST);
		glClearColor(
			headerBackgroundColor.r,
			headerBackgroundColor.g,
			headerBackgroundColor.b,
			headerBackgroundColor.a);
		glClear(GL_COLOR_BUFFER_BIT);
		glDisable(GL_SCISSOR_TEST);

		// Draw the header.
		glBindSampler(0, drawSamplerNearest);
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
