// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.raytracer;

import watt.text.format;
import watt.io.file;
import io = watt.io;

import charge.ctl;
import charge.gfx;
import charge.game;

import math = charge.math;

import power.voxel.svo;
import power.experiments.viewer;


fn loadDag(filename: string, out data: void[])
{
	// Setup raytracing code.
	data = read(filename);
	f32ptr := cast(f32*)data.ptr;
	u32ptr := cast(u32*)data.ptr;
	u64ptr := cast(u64*)data.ptr;

	id := u64ptr[0];
	frames := u64ptr[1];
	resolution := u64ptr[2];
	dataSizeInU32 := u64ptr[3];
	minX := f32ptr[ 8];
	minY := f32ptr[ 9];
	minZ := f32ptr[10];
	maxX := f32ptr[11];
	maxY := f32ptr[12];
	maxZ := f32ptr[13];

	// Calculate offset to data, both values are orignally in u32s.
	offset := (frames + 14UL) * 4;
	data = data[offset .. offset + dataSizeInU32 * 4];

/*
	io.writefln("id:         %016x", id);
	io.writefln("frames:     %s", frames);
	io.writefln("resolution: %s", resolution);
	io.writefln("ndwords:    %s", dataSizeInU32);
	io.writefln("rootMin:    %s %s %s", cast(f64)minX, cast(f64)minY, cast(f64)minZ);
	io.writefln("rootMax:    %s %s %s", cast(f64)maxX, cast(f64)maxY, cast(f64)maxZ);

	io.writefln("%s %s", dataSizeInU32 * 4, data.length);
	foreach (i; 0U .. 128U) {
		io.writefln("%04x: %08x", i, u32ptr[(offset / 4) + i]);
	}
*/
}

class RayTracer : Viewer
{
public:
	svo: SVO;
	samples: math.Average[4];


	/**
	 * For ray tracing.
	 * @{
	 */
	octBuffer: GLuint;
	octTexture: GLuint;
	/**
	 * @}
	 */


public:
	this(GameSceneManager g)
	{
		super(g);

		data: void[];
		loadDag("res/alley.dag", out data);

		glCreateBuffers(1, &octBuffer);
		glNamedBufferData(octBuffer, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);

		glCreateTextures(GL_TEXTURE_BUFFER, 1, &octTexture);
		glTextureBuffer(octTexture, GL_R32UI, octBuffer);

		svo = new SVO(octTexture);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		super.close();

		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
		if (svo !is null) { svo.close(); svo = null; }
	}

	override fn keyDown(device: CtlKeyboard, keycode: int)
	{
		switch (keycode) {
		default: super.keyDown(device, keycode);
		}
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override fn renderScene(t: GfxTarget)
	{
		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);

		view: math.Matrix4x4f;
		view.setToLookFrom(ref camPosition, ref camRotation);

		proj: math.Matrix4x4f;
		t.setMatrixToProjection(ref proj, 45.f, 0.0001f, 256.f);
		proj.setToMultiply(ref view);
		proj.transpose();

		svo.draw(ref camPosition, ref proj);

		// Check for last frames query.
		checkQuery(t);

		glDisable(GL_DEPTH_TEST);
	}

	fn checkQuery(t: GfxTarget)
	{
		vals: GLuint64[4];
		total: GLuint64;
		foreach (i, ref timer; svo.timers) {
			v: GLuint64;
			if (timer.getValue(out v)) {
				samples[i].add(v);
			}

			vals[i] = samples[i].calc();
			total += vals[i];
		}

		str := `Info:
Elapsed time:
 feedback: % 1s.%03sms
 occlude:  % 1s.%03sms
 prune:    % 1s.%03sms
 trace:    % 1s.%03sms
 total:    % 1s.%03sms
Resolution: %sx%s
w a s d - move camera
p - reset position`;

		vals[0] /= (1_000_000_000 / 1_000_000u);
		vals[1] /= (1_000_000_000 / 1_000_000u);
		vals[2] /= (1_000_000_000 / 1_000_000u);
		vals[3] /= (1_000_000_000 / 1_000_000u);
		total   /= (1_000_000_000 / 1_000_000u);
		text := format(str,
			vals[0] / 1_000, vals[0] % 1_000,
			vals[1] / 1_000, vals[1] % 1_000,
			vals[2] / 1_000, vals[2] % 1_000,
			vals[3] / 1_000, vals[3] % 1_000,
			total   / 1_000, total   % 1_000,
			t.width, t.height);

		updateText(text);
	}
}
