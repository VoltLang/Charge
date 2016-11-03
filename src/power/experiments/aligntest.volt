// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.aligntest;

import io = watt.io;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;

import charge.ctl;
import charge.gfx;
import charge.core;
import charge.game;
import charge.sys.memory;
import charge.sys.resource;

import math = charge.math;


fn calcAlign(pos: i32, level: i32) i32
{
	shift := level + 1;
	size := 1 << level;
	return ((pos + size) >> shift) << shift;
}

fn getColor(c: u32) math.Color4b
{
	steps := 16u;
	mod := c % (steps * 4);
	f := ((c % steps) + 1) / cast(f32)(steps + 1);

	r, g, b: u8;
	if (mod < steps) {
		r = cast(u8)floor(f * 256.f);
	} else if (mod < (steps * 2)) {
		g = cast(u8)floor(f * 256.f);
	} else if (mod < (steps * 3)) {
		b = cast(u8)floor(f * 256.f);
	} else {
		r = g = b = cast(u8)floor(f * 256.f);
	}

	return math.Color4b.opCall(r, g, b, 255);
}

class AlignTest : GameSimpleScene
{
public:
	i32 x, y, offsetX, offsetY, size;
	GfxDrawBuffer buf;

public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		size = 16;
		offsetX = 0;
		offsetY = 0;

		max := 8u;
		b := new GfxDrawVertexBuilder(max*max*4u);
		foreach (i; 0u .. max*max) {
			arr: u32[2];
			math.decode2(i, out arr);

			x := cast(i32)arr[0]; y := cast(i32)arr[1];

			color := getColor(i);

			x = x % 2 == 1 ? -x >> 1 : x >> 1;
			y = y % 2 == 1 ? -y >> 1 : y >> 1;
			x1 := x; x2 := x + 1;
			y1 := y; y2 := y + 1;
			b.add(cast(f32)x1, cast(f32)y1, 0.f, 0.f, color);
			b.add(cast(f32)x1, cast(f32)y2, 0.f, 0.f, color);
			b.add(cast(f32)x2, cast(f32)y2, 0.f, 0.f, color);
			b.add(cast(f32)x2, cast(f32)y1, 0.f, 0.f, color);
		}
		buf = GfxDrawBuffer.make("aligntest", b);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close()
	{

	}

	override void mouseMove(CtlMouse m, int, int)
	{
		x = m.x / size - offsetX;
		y = m.y / size - offsetY;
	}

	override void keyDown(CtlKeyboard, int keycode, dchar, scope const(char)[] m)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		default:
		}
	}

	override void render(GfxTarget t)
	{
		math.Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);
		testShader.bind();
		testShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		drawLevel(x, y, 4);
		drawLevel(x, y, 3);
		drawLevel(x, y, 2);
		drawLevel(x, y, 1);
		drawLevel(x, y, 0);
	}

	fn drawLevel(x: i32, y: i32, level: i32)
	{
		size := 1 << level;
		flipX := (x >> level) % 2 == 1;
		flipY := (y >> level) % 2 == 1;
		lsize := this.size * size;

		vec: f32[4];
		vec[0] = cast(f32)(calcAlign(x, level) * this.size);
		vec[1] = cast(f32)(calcAlign(y, level) * this.size);
		testShader.float2("offset".ptr, 1, &vec[0]);
		vec[0] = cast(f32)lsize * (flipX ? -1.f : 1.f);
		vec[1] = cast(f32)lsize * (flipY ? -1.f : 1.f);
		testShader.float2("scale".ptr, 1, &vec[0]);

		glBindVertexArray(buf.vao);
		glDrawArrays(GL_QUADS, 0, buf.num);
		glBindVertexArray(0);
	}
}

global GfxShader testShader;

global this()
{
	Core.addInitAndCloseRunners(initDraw, closeDraw);
}

void initDraw()
{
	testShader = new GfxShader(vertexShader120,
	                    fragmentShader120,
	                    ["position", "uv", "color"],
	                    ["tex"]);
}

void closeDraw()
{
	testShader.breakApart();
	testShader = null;
}

enum string vertexShader120 = `
#version 120

attribute vec2 position;
attribute vec2 uv;
attribute vec4 color;

uniform mat4 matrix;
uniform vec2 offset;
uniform vec2 scale;

varying vec4 colorFs;

void main(void)
{
	colorFs = color;
	gl_Position = matrix * vec4((position * scale) + offset, 0.0, 1.0);
}
`;

enum string fragmentShader120 = `
#version 120

varying vec4 colorFs;

void main(void)
{
	gl_FragColor = colorFs;
}
`;
