// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.viewer;

import watt.text.sink;
import watt.text.format;
import io = watt.io;

import charge.ctl;
import charge.gfx;
import charge.game;

import math = charge.math;

import power.util.counters;
import power.voxel.svo;
import power.voxel.mixed;
import power.experiments.viewer;

import voxel.svo;
import voxel.loaders.magica;


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
	this(g: GameSceneManager, frames: u32[], data: void[])
	{
		super(g);
		this.frames = frames;

		glCreateBuffers(1, &octBuffer);
		glNamedBufferData(octBuffer, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);

		glCreateTextures(GL_TEXTURE_BUFFER, 1, &octTexture);
		glTextureBuffer(octTexture, GL_R32UI, octBuffer);

		svo = new SVO(octTexture);
		mixed = new Mixed(octTexture);

		// Set the starting position.
		resetPosition(1);
	}

	fn resetPosition(pos: i32)
	{
		switch (pos) {
		default:
		case 1:
			// Down the alley.
			mCamHeading = 0.f;
			mCamPitch = 0.f;
			camPosition = math.Point3f.opCall(0.20f, 0.20f, 1.0f);
			break;
		case 2:
			mCamHeading = 0.020998f;
			mCamPitch = 0.108000f;
			camPosition = math.Point3f.opCall(0.172619f, 0.120140f, 0.939102f);
			break;
		case 3:
			// Outside looking down.
			mCamHeading = -1.182002f;
			mCamPitch = -0.576000f;
			camPosition = math.Point3f.opCall(-0.282043f, 0.623386f, 0.813192f);
			break;
		case 4:
			mCamHeading = 1.586998f;
			mCamPitch = 0.150000f;
			camPosition = math.Point3f.opCall(0.304225f, 0.137506f, 0.626945f);
			break;
		case 5:
			mCamHeading = 1.565997f;
			mCamPitch = -0.012000f;
			camPosition = math.Point3f.opCall(0.320065f, 0.133823f, 0.617499f);
			break;
		case 6:
			mCamHeading = 3.452999f;
			mCamPitch = 0.189000f;
			camPosition = math.Point3f.opCall(0.106617f, 0.135277f, 0.269312f);
			break;
		}
	}

	fn stepFrame()
	{
		if ((frame += 1) >= frames.length) {
			frame = 0;
		}
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
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			resetPosition(keycode - '0');
			break;
		case 'm': useSVO = !useSVO; break;
		case 't': animate = !animate; break;
		case 'y': stepFrame(); break;
		default: super.keyDown(device, keycode);
		}
	}

	override fn logic()
	{
		if (animate) {
			stepFrame();
		}
		super.logic();
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


		view: math.Matrix4x4d;
		view.setToLookFrom(ref camPosition, ref camRotation);

		proj: math.Matrix4x4d;
		t.setMatrixToProjection(ref proj, 45.f, 0.0001f, 256.f);


		if (useSVO) {
			temp: math.Matrix4x4f;
			temp.setToMultiplyAndTranspose(ref proj, ref view);

			svo.draw(ref camPosition, ref temp);
		} else {
			cull: math.Matrix4x4d;
			cull.setToLookFrom(ref cullPosition, ref cullRotation);

			state: Mixed.DrawInput;

			state.camPos = camPosition;
			state.camMVP.setToMultiply(ref proj, ref view);

			state.cullPos = cullPosition;
			state.cullMVP.setToMultiply(ref proj, ref cull);

			mixed.frame = frames[frame];
			mixed.draw(ref state);
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
1 2 3 4 5 6 - reset position
o - AA (%s)
t - animate (%s)
y - step frame (#%s)
m - switch renderer`, mUseAA, animate, frame);
		updateText(ss.toString());
	}
}
