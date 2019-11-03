// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module power.experiments.svo;

import watt.io.file : isFile, read;
import watt.math : PIf;
import watt.text.sink : StringSink;
import watt.text.format : format;

import lib.gl.gl33;

import ctl = charge.ctl;
import gfx = charge.gfx;
import sys = charge.sys;
import tui = charge.game.tui;
import math = charge.math;
import scene = charge.game.scene;

import charge.gfx.gl;

import power.app;
import power.experiments.viewer;

import svo = voxel.svo;
import old = voxel.old;
import gen = voxel.generators;

import voxel.loaders;


class SvoLoader : tui.WindowScene
{
public:
	app: App;
	enum NumLevels = 11u;


protected:
	mFilename: string;
	mHasRendered: bool;
	mUseTest: bool;


public:
	this(app: App, filename: string, useTest: bool)
	{
		this.app = app;
		this.mFilename = filename;
		this.mUseTest = useTest;
		super(app, 40, 5);
		setHeader(cast(immutable(u8)[])"Loading");
	}

	override fn render(t: gfx.Target)
	{
		mHasRendered = true;
		super.render(t);
	}

	override fn logic()
	{
		if (!mHasRendered) {
			return;
		}

		svoErrStr := svo.checkGraphics();
		oldErrStr := old.checkGraphics();

		// Ignore old error, if we are not using those pipelines.
		if (!mUseTest) {
			oldErrStr = null;
		}

		// Check error messages
		if (svoErrStr.length != 0 && oldErrStr.length != 0) {
			return doError(svoErrStr ~ "\n" ~ oldErrStr);
		} else if (svoErrStr.length != 0) {
			return doError(svoErrStr);
		} else if (oldErrStr.length != 0) {
			return doError(oldErrStr);
		}

		// State to give to the renderers.
		frames: u32[];
		data: void[];
		state: svo.Create;

		// First try a magica voxel level.
		if (!loadFile(mFilename, out state, out frames, out data) &&
		    !doGen(mFilename, out state, out frames, out data)) {
			return doError("Could not load or generate a level");
		}

		d := new svo.Data(ref state, data);
		obj := new svo.Entity(d, frames, NumLevels);

		app.closeMe(this);
		if (mUseTest) {
			app.push(new OldSvoViewer(app, d, obj));
		} else {
			app.push(new NewSvoViewer(app, d, obj));
		}
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	fn loadFile(filename: string, out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		if (!isFile(filename)) {
			return false;
		}

		// Load the file.
		fileData := cast(void[])read(filename);

		if (magica.isMagicaFile(fileData)) {
			return loadMagica(fileData, out c, out frames, out data);
		}

		if (chalmers.isChalmersDag(fileData)) {
			return loadChalmers(fileData, out c, out frames, out data);
		}

		return false;
	}

	fn loadMagica(fileData: void[], out c: svo.Create,
	              out frames: u32[], out data: void[]) bool
	{
		// Create the loader.
		l := new magica.Loader();

		// Load parse the file.
		return l.loadFileFromData(fileData, out frames, out data, NumLevels);
	}

	fn loadChalmers(fileData: void[], out c: svo.Create,
	                out frames: u32[], out data: void[]) bool
	{
		// Create the loader.
		l := new chalmers.Loader();

		// Load parse the file.
		return l.loadFileFromData(fileData, out c, out frames, out data);
	}

	fn doGen(arg: string, out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		switch (arg) {
		case "--gen-one":
			return genOne(out c, out frames, out data);
		case "--gen-flat", "--gen-flat-y":
			return genFlatY(out c, out frames, out data);
		default:
			return genFlatY(out c, out frames, out data);
		}
	}

	fn genOne(out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		// Reserve the first index.
		ib: svo.InputBuffer;
		ib.setup(1);

		// Load parse the file.
		og: gen.OneGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = og.gen(ref ib, NumLevels);

		data = ib.getData();
		return true;
	}

	fn genFlatY(out c: svo.Create, out frames: u32[], out data: void[]) bool
	{
		// Reserve the first index.
		ib: svo.InputBuffer;
		ib.setup(1);

		// Load parse the file.
		fg: gen.FlatGen;

		// Only one frame.
		frames = new u32[](1);
		frames[0] = fg.genYColored(ref ib, NumLevels);

		data = ib.getData();
		return true;
	}

	fn doError(str: string)
	{
		app.closeMe(this);
		app.push(new ErrrorMessageScene(app, str));
	}
}

class ErrrorMessageScene : tui.MessageScene
{
public:
	app: App;

public:
	this(app: App, str: string)
	{
		this.app = app;
		super(app, "ERROR", str);
	}

	override fn pressedOk(button: tui.Button)
	{
		app.closeMe(this);
		app.showMenu();
	}
}

abstract class SvoViewer : Viewer
{
public:
	data: svo.Data;
	obj: svo.Entity;
	animate: bool;
	pipes: old.Pipeline[];
	pipeId: u32;


protected:
	mTimeClear: gfx.TimeTracker;


public:
	this(m: scene.Manager, data: svo.Data, obj: svo.Entity)
	{
		super(m);
		this.obj = obj;
		this.data = data;
		this.mTimeClear = new gfx.TimeTracker("clear");

		// Set the starting position.
		resetPosition(1);
	}

	fn switchRenderer()
	{
		if ((pipeId += 1) >= pipes.length) {
			pipeId = 0;
		}
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


protected:
	fn checkQuery(t: gfx.Target)
	{
		ss: StringSink;
		sink := ss.sink;


		sink.format("CPU:\n");
		sys.TimeTracker.getTimings(sink);
		sink.format("\nGPU:\n");
		gfx.TimeTracker.getTimings(sink);
		sink.format("\n");
		sink.format("Resolution: %sx%s\n", t.width, t.height);
		sink.format(`w a s d - move camera
1 2 3 4 5 6 - reset position
o - AA (%s)
t - animate (%s)
y - step frame (#%s)
m - switch renderer (%s)
l - lock culling (%s)`, aa.getName(), animate, obj.frame, pipes[pipeId].name, mLockCull);
		updateText(ss.toString());
	}
}

class NewSvoViewer : SvoViewer
{
public:
	objs: svo.Entity[];


public:
	this(m: scene.Manager, data: svo.Data, obj: svo.Entity)
	{
		super(m, data, obj);
		this.objs = [obj];

		// New testing pipeline
		pipes ~= new svo.Pipeline(data);
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override fn renderScene(t: gfx.Target)
	{
		pipe := cast(svo.Pipeline)pipes[pipeId];

		// Clear the screen.
		mTimeClear.start();
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);
		mTimeClear.stop();

		// Constant for now.
		fov := 45.f;

		proj: math.Matrix4x4d;
		t.setMatrixToProjection(ref proj, fov, 0.0001f, 256.f);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref camPosition, ref camRotation);

		cull: math.Matrix4x4d;
		cull.setToLookFrom(ref cullPosition, ref cullRotation);

		state: old.Draw;
		state.targetWidth = t.width;
		state.targetHeight = t.height;
		state.fov = fov;
		state.frame = obj.start;
		state.numLevels = obj.numLevels;
		state.camPos = camPosition;
		state.camMVP.setToMultiply(ref proj, ref view);
		state.cullPos = cullPosition;
		state.cullMVP.setToMultiply(ref proj, ref cull);

		pipe.draw(ref state);

		// Check for last frames query.
		checkQuery(t);

		glDisable(GL_DEPTH_TEST);
	}
}

class OldSvoViewer : SvoViewer
{
public:
	this(m: scene.Manager, data: svo.Data, obj: svo.Entity)
	{
		super(m, data, obj);

		// New testing pipeline
		pipes ~= new svo.Pipeline(data);

		// Create the pipelines.
		for (i: i32; i < old.StepPipeline.Kind.Num; i++) {
			pipes ~= new old.StepPipeline(data.texture, ref data.create, i);
		}
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override fn renderScene(t: gfx.Target)
	{
		// Clear the screen.
		mTimeClear.start();
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);
		mTimeClear.stop();

		// Constant for now.
		fov := 45.f;

		proj: math.Matrix4x4d;
		t.setMatrixToProjection(ref proj, fov, 0.0001f, 256.f);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref camPosition, ref camRotation);

		cull: math.Matrix4x4d;
		cull.setToLookFrom(ref cullPosition, ref cullRotation);

		state: old.Draw;
		state.targetWidth = t.width;
		state.targetHeight = t.height;
		state.fov = fov;
		state.frame = obj.start;
		state.numLevels = obj.numLevels;
		state.camPos = camPosition;
		state.camMVP.setToMultiply(ref proj, ref view);
		state.cullPos = cullPosition;
		state.cullMVP.setToMultiply(ref proj, ref cull);

		pipes[pipeId].draw(ref state);

		// Check for last frames query.
		checkQuery(t);

		glDisable(GL_DEPTH_TEST);
	}
}
