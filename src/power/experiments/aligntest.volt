// Copyright 2016-2019, Jakob Bornecrantz.
// Copyright 2019-2022, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
module power.experiments.aligntest;

import io = watt.io;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;

import lib.gl.gl33;

import core = charge.core;
import ctl = charge.ctl;
import gfx = charge.gfx;
import math = charge.math;
import scene = charge.game.scene;

import charge.gfx.gl;
import charge.sys.memory;


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

	return math.Color4b.from(r, g, b, 255);
}

class AlignTest : scene.Simple
{
public:
	x, y, lookX, lookY, offsetX, offsetY: i32;
	buf: gfx.DrawBuffer;
	testShader: gfx.Shader;


private:
	mDragging, mLooking: bool;


public:
	this(g: scene.Manager)
	{
		super(g, Type.Game);

		testShader = new gfx.Shader("aligntest", vertexShader120,
		                    fragmentShader120,
		                    ["position", "uv", "color"],
		                    ["tex"]);

		lookX = lookY = 6;
		offsetX = 0;
		offsetY = 0;

		max := 8u;
		b := new gfx.DrawVertexBuilder(max*max*6u);
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
			b.add(cast(f32)x2, cast(f32)y2, 0.f, 0.f, color);
			b.add(cast(f32)x2, cast(f32)y1, 0.f, 0.f, color);
			b.add(cast(f32)x1, cast(f32)y1, 0.f, 0.f, color);
		}
		buf = gfx.DrawBuffer.make("aligntest", b);
		gfx.destroy(ref b);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		gfx.destroy(ref testShader);
		gfx.reference(ref buf, null);
	}

	override fn mouseMove(m: ctl.Mouse, int, int)
	{
		if (mDragging) {
			x = m.x - offsetX;
			y = m.y - offsetY;
		}
		if (mLooking) {
			lookX = m.x - offsetX;
			lookY = m.y - offsetY;
		}
	}

	override fn mouseDown(m: ctl.Mouse, button: i32)
	{
		if (button == 1 && !mLooking) {
			mDragging = true;
			x = m.x - offsetX;
			y = m.y - offsetY;
		}
		if (button == 3 && !mDragging) {
			mLooking = true;
			lookX = m.x - offsetX;
			lookY = m.y - offsetY;
		}
	}

	override fn mouseUp(m: ctl.Mouse, button: i32)
	{
		if (button == 1) {
			mDragging = false;
		}
		if (button == 3) {
			mLooking = false;
		}
	}

	override fn keyDown(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 'n': core.get().resize(800, 600, core.WindowMode.Normal); break;
		case 'f': core.get().resize(800, 600, core.WindowMode.Fullscreen); break;
		case 'd': core.get().resize(800, 600, core.WindowMode.FullscreenDesktop); break;
		default:
		}
	}

	override fn renderView(t: gfx.Target, ref viewInfo: gfx.ViewInfo)
	{
		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);
		testShader.bind();
		testShader.matrix4("matrix", 1, true, ref mat);

		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);


		drawLevel(7);
		drawLevel(6);
		drawLevel(5);
		drawLevel(4);

		vec: f32[4];
		vec[0] = 0.f;
		vec[1] = 0.f;
		testShader.float2("offset".ptr, 1, &vec[0]);
		vec[0] = 0.f;
		vec[1] = 0.f;
		testShader.float2("scale".ptr, 1, &vec[0]);
	}

	fn drawLevel(level: i32)
	{
		fx := cast(f32)(lookX - x);
		fy := cast(f32)(lookY - y);
		d := sqrt(fx * fx + fy * fy);
		if (d == 0.0) {
			fy = 1.f;
		} else {
			fx /= d;
			fy /= d;
		}

		size := 1 << level;
		offX := cast(i32)(fx * 3.0f * size);
		offY := cast(i32)(fy * 3.0f * size);

		resultX := x + offX;
		resultY := y + offY;

		flipX := (resultX >> level) % 2 == 1;
		flipY := (resultY >> level) % 2 == 1;

		vec: f32[4];
		vec[0] = cast(f32)calcAlign(resultX, level);
		vec[1] = cast(f32)calcAlign(resultY, level);
		testShader.float2("offset".ptr, 1, &vec[0]);
		vec[0] = cast(f32)size * (flipX ? -1.f : 1.f);
		vec[1] = cast(f32)size * (flipY ? -1.f : 1.f);
		testShader.float2("scale".ptr, 1, &vec[0]);

		glBindVertexArray(buf.vao);
		glDrawArrays(GL_TRIANGLES, 0, buf.num);
		glBindVertexArray(0);
	}
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
