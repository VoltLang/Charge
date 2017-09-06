// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.viewer;

import io = watt.io;

import watt.math.floating;
import watt.text.sink;
import watt.text.format;

import ctl = charge.ctl;
import gfx = charge.gfx;
import math = charge.math;

import game = charge.game;
import charge.gfx.gl;

import svo = voxel.svo;

import power.experiments.viewer;


class RayTracer : Viewer
{
public:
	data: svo.Data;
	obj: svo.Entity;
	pipes: svo.Pipeline[];
	pipeId: u32;
	animate: bool;


public:
	this(g: game.SceneManager, data: svo.Data, obj: svo.Entity)
	{
		super(g);
		this.data = data;
		this.obj = obj;

		for (i: i32; i < svo.Pipeline.Kind.Num; i++) {
			pipes ~= new svo.Pipeline(data.texture, ref data.create, i);
		}

		// Set the starting position.
		resetPosition(1);
	}

	fn resetPosition(pos: i32)
	{
		switch (pos) {
		default:
		case 1:
			// Looking at 0, 0, 0 in.
			mCamHeading = -2.358001f;
			mCamPitch = -0.477000f;
			camPosition = math.Point3f.opCall(-0.183648f, 0.293329f, -0.172469f);
			break;
		case 2:
			mCamHeading = -1.979999f;
			mCamPitch = -0.297000f;
			camPosition = math.Point3f.opCall(0.091741f, 0.083281f, 0.147087f);
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
		case 7:
			// Down the alley.
			mCamHeading = 0.f;
			mCamPitch = 0.f;
			camPosition = math.Point3f.opCall(0.20f, 0.20f, 1.0f);
			break;
		case 9:
			// Test
			mCamHeading = PIf;
			mCamPitch = 0.f;
			camPosition = math.Point3f.opCall(0.0f, 0.0f, -0.940017f);
			break;
		case 0:
			// Origin
			mCamHeading = 0.f;
			mCamPitch = 0.f;
			camPosition = math.Point3f.opCall(0.0f, 0.0f, 0.0f);
			break;
/*
		case 2:
			mCamHeading = 0.020998f;
			mCamPitch = 0.108000f;
			camPosition = math.Point3f.opCall(0.172619f, 0.120140f, 0.939102f);
			break;
*/
		}
	}

	fn switchRenderer()
	{
		if ((pipeId += 1) >= pipes.length) {
			pipeId = 0;
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

		foreach (ref m; pipes) {
			m.close();
			m = null;
		}
		pipes = null;
	}

	override fn keyDown(device: ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			resetPosition(keycode - '0');
			break;
		case 'm': switchRenderer(); break;
		case 't': animate = !animate; break;
		case 'y': obj.stepFrame(); break;
		default: super.keyDown(device, keycode);
		}
	}

	override fn logic()
	{
		if (animate) {
			obj.stepFrame();
		}
		super.logic();
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override fn renderScene(t: gfx.Target)
	{
		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);
		fov := 45.f;


		proj: math.Matrix4x4d;
		t.setMatrixToProjection(ref proj, fov, 0.0001f, 256.f);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref camPosition, ref camRotation);

		cull: math.Matrix4x4d;
		cull.setToLookFrom(ref cullPosition, ref cullRotation);

		state: svo.Draw;
		state.targetWidth = t.width;
		state.targetHeight = t.height;
		state.fov = fov;
		state.frame = obj.start;
		state.camPos = camPosition;
		state.camMVP.setToMultiply(ref proj, ref view);
		state.cullPos = cullPosition;
		state.cullMVP.setToMultiply(ref proj, ref cull);

		pipes[pipeId].draw(ref state);

		// Check for last frames query.
		checkQuery(t);

		glDisable(GL_DEPTH_TEST);
	}

	fn checkQuery(t: gfx.Target)
	{
		ss: StringSink;
		sink := ss.sink;

		sink.format("Info:\n");
		pipes[pipeId].counters.print(sink);
		sink.format("Resolution: %sx%s\n", t.width, t.height);
		sink.format(`w a s d - move camera
1 2 3 4 5 6 - reset position
o - AA (%s)
t - animate (%s)
y - step frame (#%s)
m - switch renderer (%s)
l - lock culling (%s)`, mUseAA, animate, obj.frame, pipes[pipeId].name, mLockCull);
		updateText(ss.toString());
	}
}
