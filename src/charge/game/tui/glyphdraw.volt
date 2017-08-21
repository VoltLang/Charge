// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.game.tui.glyphdraw;

import charge.game.tui.grid;


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
