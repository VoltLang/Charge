// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module ohmd.game;

import lib.gl.gl45;
import lib.ohmd;
static import lib.ohmd.loader;

import io = watt.io;

import watt.library;
import watt.conv;
import watt.text.sink;
import watt.text.format;
import watt.math.floating;

import core = charge.core;
import ctl = charge.ctl;
import gfx = charge.gfx;
import math = charge.math;
import game = charge.game;
import scene = charge.game.scene;

import charge.gfx.gl;
import charge.util.stopwatch;

import voxel.svo.design;
import voxel.svo.buffers;
import voxel.svo.textures;
import voxel.old.shaders;

import ohmd.text;
import ohmd.model;
import ohmd.hmd;


class Game : scene.ManagerApp
{
public:
	ctx: Context;
	dev: Device;


public:
	this(args: string[])
	{
		rtStart: StopWatch;
		rtStart.fromInit();

		coreStart: StopWatch;
		coreStart.startAndStop(ref rtStart);

		// First init core.
		opts := new core.Options();
		opts.title = "VR Demo";
		opts.width = 800;
		opts.height = 600;
		opts.windowMode = core.WindowMode.Normal;
		super(opts);

		gameStart: StopWatch;
		gameStart.startAndStop(ref coreStart);

		if (!checkVersion() ||
		    !setupGL() ||
		    !loadOpenHMD() ||
		    !setupScene()) {
			core.quit();
			return;
		}

		gameStart.stop();

		rtU := rtStart.microseconds;
		coreU := coreStart.microseconds;
		gameU := gameStart.microseconds;
		io.output.writefln("rt:%7s.%02sms\ncore:%5s.%02sms\ngame:%5s.%02sms",
			rtU / 1000, (rtU / 10) % 100,
			coreU / 1000, (coreU / 10) % 100,
			gameU / 1000, (gameU / 10) % 100);
		io.output.flush();
	}

	override fn close()
	{
		if (dev !is null) {
			dev.close();
			dev = null;
		}

		if (ctx !is null) {
			ctx.close();
			ctx = null;
		}

		super.close();
	}

	fn setupGL() bool
	{
		glDisable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
		return true;
	}

	fn setupScene() bool
	{
		push(new Scene(this, ctx, dev));
		return true;
	}

	fn loadOpenHMD() bool
	{
		ctx = Context.load();
		if (ctx is null) {
			ctx = new NoContext();
		}

		dev = ctx.getDevice();
		if (dev is null) {
			mCore.panic("Failed to open OpenHMD device");
			return false;
		}

		return true;
	}

	static fn checkVersion() bool
	{
		return true;
	}
}

class Scene : scene.Simple
{
public:
	//! The OpenHMD context.
	ctx: Context;
	//! The device we are using.
	dev: Device;
	
	//! Heads up text.
	text: Text;

	//! Keeping track of the camera. @{
	camPosition: math.Point3f;
	camRotation: math.Quatf;
	//! @}

	store: ShaderStore;
	quads: gfx.Shader;

	mIndexBuffer: GLuint;
	mElementsVAO: GLuint;

	//! The HMD model.
	hmd: VoxelModel;
	tile1M: VoxelModel;
	models: VoxelModel[];


protected:
	mAA: gfx.AA;
	mCounters: gfx.Counters;

	//! Keeping track of the light. @{
	mLightHeading, mLightPitch: f32;
	mLightDirection: math.Vector3f;
	mLightIsDragging: bool;
	//! @}

	mLevels: u32;

	mCamHeading, mCamPitch, mDistance: f32;
	mCamUp, mCamFore, mCamBack, mCamLeft, mCamRight: bool;
	mCamIsDragging: bool;

	mEdgeTexture: GLuint;
	mEdgeSampler: GLuint;


public:
	this(g: scene.Manager, ctx: Context, dev: Device)
	{
		super(g, Type.Game);
		this.ctx = ctx;
		this.dev = dev;
		this.mLevels = 6;
		this.mCounters = new gfx.Counters("scene", "aa");

		c: Create;
		store = getStore(ref c);
		quads = store.makeQuadsShader(0, mLevels);
		text = new Text("Info:");

		// Get the edge texture.
		mEdgeTexture = createEdgeCubeTexture();
		mEdgeSampler = createEdgeCubeSampler();

		// Setup a VAO.
		mIndexBuffer = createIndexBuffer(4096*2u);
		glCreateVertexArrays(1, &mElementsVAO);
		glVertexArrayElementBuffer(mElementsVAO, mIndexBuffer);

		// Load the HMD model.
		data := import("ohmd/dk2.vox");
		hmd = VoxelModel.fromMagicalData(cast(const(void)[])data);
		data = import("ohmd/tile_1m.vox");
		tile1M = VoxelModel.fromMagicalData(cast(const(void)[])data);
		floor1 := VoxelModel.fromModel(tile1M);
		floor1.pos = math.Point3f.opCall(0.5f, 0.5f, 0.f);
		floor1.rot = math.Quatf.opCall(PIf, PIf * -0.5f, 0.f);
		floor2 := VoxelModel.fromModel(tile1M);
		floor2.pos = math.Point3f.opCall(0.5f, 1.5f, 0.f);
		floor2.rot = math.Quatf.opCall(PIf, PIf * -0.5f, 0.f);
		models = [hmd, floor1, floor2];

		// Setup the light.
		mLightHeading = 0.342997f;
		mLightPitch = -0.783001f;

		// Setup the camera.
		camRotation = math.Quatf.opCall();
		setPosition(0);

		// Default HMD position.
		hmd.pos = math.Point3f.opCall(0.5f, 1.8f, 0.5f);

		// Force double AA on.
		mAA.kind = gfx.AA.Kind.Double;
	}

	override fn logic()
	{
		// Update the light.
		mLightDirection = math.Quatf.opCall(mLightHeading, mLightPitch, 0.0f) * math.Vector3f.Forward;

		// Update camera.
		camRotation = math.Quatf.opCall(mCamHeading, mCamPitch, 0.0f);
		sum: math.Vector3f;

		if (mCamFore != mCamBack) {
			v: math.Vector3f;
			v.z = mCamBack ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (mCamLeft != mCamRight) {
			v: math.Vector3f;
			v.x = mCamRight ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (mCamUp) {
			sum.y += 1;
		}

		if (sum.lengthSqrd() != 0.f) {
			sum.normalize();
			sum.scale(0.004f);
			camPosition += sum;
		}

		// Update HMD
		ctx.update();
		dev.getPosAndRot(ref hmd.pos, ref hmd.rot);

		ss: StringSink;
		ss.sink.format(`Info:
rotation: %s %s %s %s
`, hmd.rot.x, hmd.rot.y, hmd.rot.z, hmd.rot.w);
		mCounters.print(ss.sink);
		text.update(ss.toString());
	}

	override fn keyDown(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 32: mCamUp = true; break;
		case 'w': mCamFore = true; break;
		case 's': mCamBack = true; break;
		case 'a': mCamLeft = true; break;
		case 'd': mCamRight = true; break;
		case 'q': printInfo(); break;
		case '1': setPosition(0); break;
		case '2': setPosition(1); break;
		default:
		}
	}

	override fn keyUp(ctl.Keyboard, keycode: int)
	{
		switch (keycode) {
		case 32: mCamUp = false; break;
		case 'w': mCamFore = false; break;
		case 's': mCamBack = false; break;
		case 'a': mCamLeft = false; break;
		case 'd': mCamRight = false; break;
		default:
		}
	}

	override fn dropControl()
	{
		super.dropControl();
		mCamUp = false;
		mCamFore = false;
		mCamBack = false;
		mCamLeft = false;
		mCamRight = false;
		mCamIsDragging = false;
		mLightIsDragging = false;
	}

	override fn mouseMove(m: ctl.Mouse, x: int, y: int)
	{
		if (mCamIsDragging) {
			mCamHeading += x * -0.003f;
			mCamPitch += y * -0.003f;
		}

		if (mCamPitch < -(PIf/2)) mCamPitch = -(PIf/2);
		if (mCamPitch >  (PIf/2)) mCamPitch =  (PIf/2);

		if (mLightIsDragging) {
			mLightHeading += x * -0.003f;
			mLightPitch += y * -0.003f;
		}

		if (mLightPitch < -(PIf/2)) mLightPitch = -(PIf/2);
		if (mLightPitch >  (PIf/2)) mLightPitch =  (PIf/2);
	}

	override fn mouseDown(m: ctl.Mouse, button: int)
	{
		switch (button) {
		case 1:
			m.setRelativeMode(true);
			mCamIsDragging = true;
			break;
		case 3:
			m.setRelativeMode(true);
			mLightIsDragging = true;
			break;
		case 4: // Mouse wheel up.
			mDistance -= 0.1f;
			if (mDistance < 0.0f) {
				mDistance = 0.0f;
			}
			break;
		case 5: // Mouse wheel down.
			mDistance += 0.1f;
			break;
		default:
		}
	}

	override fn mouseUp(m: ctl.Mouse, button: int)
	{
		switch (button) {
		case 1:
			mCamIsDragging = false;
			break;
		case 3:
			mLightIsDragging = false;
			break;
		default:
		}

		if (!mLightIsDragging && !mCamIsDragging) {
			m.setRelativeMode(false);
		}
	}

	override fn render(t: gfx.Target)
	{
		glFinish();
		mCounters.start(0);

		// Render to the aa
		mAA.bind(t);

		// Clear the screen.
		glClearColor(0.8f, 0.8f, 0.8f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glUseProgram(0);

		// What it says on the tin.
		drawScene(t);

		mCounters.stop(0);
		mCounters.start(1);

		// unbind and draw it to the screen.
		mAA.resolveToAndBind(t);

		mCounters.stop(1);

		// Draw text on the screen.
		text.draw(t);
	}


	/*
	 *
	 * Helper functions.
	 *
	 */

	fn drawScene(t: gfx.Target)
	{
		glCheckError();
		glEnable(GL_DEPTH_TEST);
		glBindTextureUnit(1, mEdgeTexture);
		glBindSampler(1, mEdgeSampler);

		view: math.Matrix4x4d;
		view.setToLookFrom(ref camPosition, ref camRotation);
		proj: math.Matrix4x4d;
		t.setMatrixToProjection(ref proj, 45.f, 0.05f, 256.f);
		vp: math.Matrix4x4d;
		vp.setToMultiply(ref proj, ref view);

		state: StepState;

		normalMat: math.Matrix3x3f;

		glBindVertexArray(mElementsVAO);
		quads.bind();

		foreach (m; models) {
			updateState(ref state.matrix, ref normalMat,
			            ref state.camPosition,
			            ref vp, ref camPosition, m);
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, m.buffer);
			quads.float3("uCameraPos".ptr, state.camPosition.ptr);
			quads.matrix4("uMatrix", 1, false, ref state.matrix);
			quads.matrix3("uNormalMatrix", 1, false, ref normalMat);
			quads.float3("uLightNormal".ptr, mLightDirection.ptr);
			glDrawElements(GL_TRIANGLE_STRIP, 12 * cast(GLsizei)m.num, GL_UNSIGNED_INT, null);
		}

		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, 0);
		quads.unbind();
		glBindVertexArray(0);
		glBindTextureUnit(1, 0);
		glBindSampler(1, 0);

		glCheckError();
		glDisable(GL_DEPTH_TEST);
	}

	fn updateState(ref outMVP: math.Matrix4x4f,
	               ref outNormal: math.Matrix3x3f,
	               ref outCamPos: math.Point3f,
	               ref vp: math.Matrix4x4d, ref camPos: math.Point3f,
	               model: VoxelModel)
	{
		voxelSize := 1.0f / (1 << mLevels);
		off := model.rot * (model.off * voxelSize);
		offPos := model.pos - off;

		m: math.Matrix4x4d;
		m.setToModel(ref offPos, ref model.rot);

		normal: math.Matrix3x3d;
		normal.setToInverse(ref m);

		vec := model.rot.inverse() * (camPos - offPos);
		outCamPos = math.Point3f.opCall(vec);
		outNormal.setTo(ref normal);
		outMVP.setToMultiplyAndTranspose(ref vp, ref m);
	}

	fn setPosition(v: i32)
	{
		switch (v) {
		default:
		case 0:
			mCamHeading = -0.717004f;
			mCamPitch = -0.603000f;
			camPosition = math.Point3f.opCall(-0.803765f, 2.590106f, 1.599766f);
			break;
		case 1:
			mCamHeading = 0.0f;
			mCamPitch = -0.300f;
			camPosition = math.Point3f.opCall(0.5f, 1.86f, 0.62f);
			break;
		}
	}
	fn printInfo()
	{
		io.writefln("\t\tmCamHeading = %sf;", cast(f64)mCamHeading);
		io.writefln("\t\tmCamPitch = %sf;", cast(f64)mCamPitch);
		io.writefln("\t\tcamPosition = math.Point3f.opCall(%sf, %sf, %sf);",
			cast(f64)camPosition.x, cast(f64)camPosition.y,
			cast(f64)camPosition.z);

		x := cast(i32)floor(camPosition.x * 2048);
		y := cast(i32)floor(camPosition.y * 2048);
		z := cast(i32)floor(camPosition.z * 2048);

		io.writefln("%3s %3s %3s", x, y, z);
		io.output.flush();
	}
}
