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


fn alignAxis(pos: i32) i32
{
	return ((pos - 1) >> 1) * 2;
}

fn alignAxis(pos: i32, level: i32) i32
{
	return (((pos >> (level - 1)) - 1) >> 1) * (1 << level);
}

class AlignTest : GameSimpleScene
{
public:
	i32 x, y, offsetX, offsetY, size;


public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		size = 2;
		offsetX = 100;
		offsetY = 100;
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

	override void render(GfxTarget t)
	{
		math.Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);
		testShader.bind();
		testShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		x1 := alignAxis(x);
		x2 := alignAxis(x >> 1) *  2;
		x3 := alignAxis(x >> 2) *  4;
		x4 := alignAxis(x >> 3) *  8;
		x5 := alignAxis(x >> 4) * 16;

		y1 := alignAxis(y);
		y2 := alignAxis(y >> 1) *  2;
		y3 := alignAxis(y >> 2) *  4;
		y4 := alignAxis(y >> 3) *  8;
		y5 := alignAxis(y >> 4) * 16;

		if (x1 != alignAxis(x, 1)) { io.writefln("1"); }
		if (x2 != alignAxis(x, 2)) { io.writefln("2"); }
		if (x3 != alignAxis(x, 3)) { io.writefln("3"); }
		if (x4 != alignAxis(x, 4)) { io.writefln("4"); }
		if (x5 != alignAxis(x, 5)) { io.writefln("5"); }

		glBegin(GL_QUADS);
		doLoop(x5, y5, 16);
		doLoop(x4, y4, 8);
		doLoop(x3, y3, 4);
		doLoop(x2, y2, 2);
		doLoop(x1, y1, 1);
		glEnd();
	}

	fn doLoop(x: i32, y: i32, size: i32)
	{
		foreach (i; 0 .. 16) {
			foreach(k; 0 .. 16) {
				color(i * 4 + k + i);
				tX := x + k * size - size * 6;
				tY := y + i * size - size * 6;
				draw(tX, tY, size);
			}
		}
	}

	fn color(c: i32)
	{
		switch (c % 4) {
		default: glColor4f(1.f, 0.f, 1.f, 1.f); break;
		case 0: glColor4f(1.f, 1.f, 1.f, 1.f); break;
		case 1: glColor4f(0.f, 0.f, 0.f, 1.f); break;
		case 2: glColor4f(1.f, 0.f, 0.f, 1.f); break;
		case 3: glColor4f(0.f, 1.f, 0.f, 1.f); break;
		case 4: glColor4f(0.f, 0.f, 1.f, 1.f); break;
		}
	}

	fn draw(x: i32, y: i32, size: i32)
	{
		lsize := size * this.size;
		x1 := x * this.size + offsetX * this.size;
		y1 := y * this.size + offsetY * this.size;

		glVertex2i(x1        , y1        );
		glVertex2i(x1        , y1 + lsize);
		glVertex2i(x1 + lsize, y1 + lsize);
		glVertex2i(x1 + lsize, y1        );
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

uniform mat4 matrix;

varying vec4 colorFs;

void main(void)
{
	colorFs = gl_Color;
	gl_Position = matrix * vec4(position, 0.0, 1.0);
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
