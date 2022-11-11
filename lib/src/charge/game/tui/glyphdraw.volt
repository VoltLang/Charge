// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module charge.game.tui.glyphdraw;

import charge.game.tui.grid;
import watt.text.sink : SinkArg;


enum TabSize = 8;

fn makeTextLayout(text: SinkArg, out w: u32, out h: u32)
{
	x, y, mX, mY: u32;
	foreach (dchar c; text) {
		switch (c) {
		case '\t':
			x += (TabSize - (x % TabSize));
			break;
		case '\n':
			y++;
			goto case;
		case '\r':
			x = 0;
			break;
		default:
			x++;
			if (x > mX) { mX = x; }
			mY = y + 1;
			break;
		}
	}

	w = mX;
	h = mY;
}

fn makeText(grid: Grid, x: i32, y: i32, text: SinkArg)
{
	currX, currY: i32;

	foreach (dchar c; text) {
		switch (c) {
		case '\t':
			currX += (TabSize - (currX % TabSize));
			break;
		case '\n':
			currY++;
			goto case;
		case '\r':
			currX = 0;
			break;
		default:
			grid.put(currX + x, currY + y, cast(u8)c);
			currX++;
			break;
		}
	}
}

fn makeButton(grid: Grid, x: i32, y: i32, width: u32, single: bool,
              glyphs: scope const(u8)[])
{
	if (width < 2 && width - 2 < glyphs.length) {
		width = cast(u32)(glyphs.length + 2);
	}

	if (single) {
		makeFrameSingle(grid, x, y, width, 3);
	} else {
		makeFrameDouble(grid, x, y, width, 3);
	}

	start := cast(i32)((width / 2) - (glyphs.length / 2) + cast(u32)x);
	foreach (glyph; glyphs) {
		grid.put(start++, y+1, glyph);
	}
}

fn makeFrameSingle(grid: Grid, x: i32, y: i32, w: u32, h: u32)
{
	x2 := x + cast(i32)w - 1;
	y2 := y + cast(i32)h - 1;

	foreach (i; x+1 .. x2) {
		grid.put( i,  y, SingleGuiElememts.HORIZONTAL_LINE);
	}
	foreach (i; x+1 .. x2) {
		grid.put( i, y2, SingleGuiElememts.HORIZONTAL_LINE);
	}
	foreach (i; y+1 .. y2) {
		grid.put( x,  i, SingleGuiElememts.VERTICAL_LINE);
	}
	foreach (i; y+1 .. y2) {
		grid.put(x2,  i, SingleGuiElememts.VERTICAL_LINE);
	}

	grid.put( x,  y, SingleGuiElememts.TOP_LEFT);
	grid.put(x2,  y, SingleGuiElememts.TOP_RIGHT);
	grid.put(x2, y2, SingleGuiElememts.BOTTOM_RIGHT);
	grid.put( x, y2, SingleGuiElememts.BOTTOM_LEFT);
}

fn makeFrameDouble(grid: Grid, x: i32, y: i32, w: u32, h: u32)
{
	x2 := x + cast(i32)w - 1;
	y2 := y + cast(i32)h - 1;

	foreach (i; x+1 .. x2) {
		grid.put( i,  y, DoubleGuiElememts.HORIZONTAL_LINE);
	}
	foreach (i; x+1 .. x2) {
		grid.put( i, y2, DoubleGuiElememts.HORIZONTAL_LINE);
	}
	foreach (i; y+1 .. y2) {
		grid.put( x,  i, DoubleGuiElememts.VERTICAL_LINE);
	}
	foreach (i; y+1 .. y2) {
		grid.put(x2,  i, DoubleGuiElememts.VERTICAL_LINE);
	}

	grid.put( x,  y, DoubleGuiElememts.TOP_LEFT);
	grid.put(x2,  y, DoubleGuiElememts.TOP_RIGHT);
	grid.put(x2, y2, DoubleGuiElememts.BOTTOM_RIGHT);
	grid.put( x, y2, DoubleGuiElememts.BOTTOM_LEFT);
}

enum SingleGuiElememts : u8 {
	TOP_LEFT        = 218,
	TOP_RIGHT       = 191,
	BOTTOM_LEFT     = 192,
	BOTTOM_RIGHT    = 217,
	VERTICAL_LINE   = 179,
	HORIZONTAL_LINE = 196,
}

enum DoubleGuiElememts : u8 {
	TOP_LEFT        = 201,
	TOP_RIGHT       = 187,
	BOTTOM_LEFT     = 200,
	BOTTOM_RIGHT    = 188,
	VERTICAL_LINE   = 186,
	HORIZONTAL_LINE = 205,
}
