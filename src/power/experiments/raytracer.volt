// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.raytracer;

import watt.text.sink;
import watt.text.format;
import watt.io.file;
import io = watt.io;

import charge.ctl;
import charge.gfx;
import charge.game;

import math = charge.math;

import power.util.counters;
import power.voxel.svo;
import power.voxel.mixed;
import power.experiments.viewer;


fn loadDag(filename: string, out data: void[], out frames: u32[])
{
	// Setup raytracing code.
	data = read(filename);
	f32ptr := cast(f32*)data.ptr;
	u32ptr := cast(u32*)data.ptr;
	u64ptr := cast(u64*)data.ptr;

	id := u64ptr[0];
	numFrames := u64ptr[1];
	resolution := u64ptr[2];
	dataSizeInU32 := u64ptr[3];
	minX := f32ptr[ 8];
	minY := f32ptr[ 9];
	minZ := f32ptr[10];
	maxX := f32ptr[11];
	maxY := f32ptr[12];
	maxZ := f32ptr[13];

	// Calculate offset to data, both values are orignally in u32s.
	offset := (numFrames + 14UL) * 4;
	frames = u32ptr[14UL .. 14UL + numFrames];
	data = data[offset .. offset + dataSizeInU32 * 4];

/*
	io.writefln("id:         %016x", id);
	io.writefln("numFrames:  %s", numFrames);
	io.writefln("resolution: %s", resolution);
	io.writefln("ndwords:    %s", dataSizeInU32);
	io.writefln("rootMin:    %s %s %s", cast(f64)minX, cast(f64)minY, cast(f64)minZ);
	io.writefln("rootMax:    %s %s %s", cast(f64)maxX, cast(f64)maxY, cast(f64)maxZ);

	foreach (i; 0 .. numFrames) {
		io.writefln("frame %02s: %s", numFrames, frames[i]);
	}

	io.writefln("%s %s", dataSizeInU32 * 4, data.length);
	foreach (i; 0U .. 128U) {
		io.writefln("%04x: %08x", i, u32ptr[(offset / 4) + i]);
	}
*/
}

class RayTracer : Viewer
{
public:
	useSVO: bool;
	svo: SVO;
	mixed: Mixed;
	frame: u32;
	frames: u32[];
	animate: bool;


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
		loadDag("res/alley.dag", out data, out frames);

		glCreateBuffers(1, &octBuffer);
		glNamedBufferData(octBuffer, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);

		glCreateTextures(GL_TEXTURE_BUFFER, 1, &octTexture);
		glTextureBuffer(octTexture, GL_R32UI, octBuffer);

		svo = new SVO(octTexture);
		mixed = new Mixed(octTexture);
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
		case 'm': useSVO = !useSVO; break;
		case 't': animate = !animate; break;
		case 'c': mixed.useCubes = !mixed.useCubes; break;
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

		if (useSVO) {
			svo.draw(ref camPosition, ref proj);
		} else {
			mixed.frame = frames[frame];
			if ((frame += animate) >= frames.length) {
				frame = 0;
			}
			mixed.draw(ref camPosition, ref proj);
		}

		// Check for last frames query.
		checkQuery(t);

		glDisable(GL_DEPTH_TEST);
	}

	fn checkQuery(t: GfxTarget)
	{
		ss: StringSink;
		sink := ss.sink;

		sink.format("Info:\n");
		if (useSVO) {
			svo.counters.print(sink);
		} else {
			mixed.counters.print(sink);
		}
		sink.format("Resolution: %sx%s\n", t.width, t.height);
		sink.format(`w a s d - move camera
p - reset position
t - animate
m - switch renderer
c - use cubes (%s)`, mixed.useCubes);
		updateText(ss.toString());
	}
}
