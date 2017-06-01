// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.viewer;

import io = watt.io;
import watt.math;

import charge.ctl;
import charge.gfx;
import charge.game;
import charge.sys.resource;

import math = charge.math;


/*!
 * Helper class if you want to draw a module and some text.
 */
class Viewer : GameSimpleScene
{
public:
	// AA
	mUseAA: bool;
	aa: GfxAA;

	// Rotation stuff.
	isDragging: bool;
	camPosition: math.Point3f;
	camRotation: math.Quatf;
	cullPosition: math.Point3f;
	cullRotation: math.Quatf;

	//! Text rendering stuff.
	textVbo: GfxDrawBuffer;
	textBuilder: GfxDrawVertexBuilder;
	textState: GfxBitmapState;


protected:
	mLockCull: bool;
	mCamHeading, mCamPitch, distance: f32;
	mCamUp, mCamFore, mCamBack, mCamLeft, mCamRight: bool;


public:
	this(g: GameSceneManager)
	{
		super(g, Type.Game);
		mUseAA = false;

		textState.glyphWidth = cast(int)gfxBitmapTexture.width / 16;
		textState.glyphHeight = cast(int)gfxBitmapTexture.height / 16;
		textState.offX = 16;
		textState.offY = 16;

		text := "Info";
		textBuilder = new GfxDrawVertexBuilder(0);
		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo = GfxDrawBuffer.make("power/exp/text", textBuilder);

		updateText("Info:");
	}

	fn renderScene(t: GfxTarget)
	{

	}

	fn updateText(text: string)
	{
		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo.update(textBuilder);
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
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		aa.breakApart();
		if (textVbo !is null) { textVbo.decRef(); textVbo = null; }
	}

	override fn logic()
	{
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
			sum.scale(0.001f);
			camPosition += sum;
		}

		if (!mLockCull) {
			cullPosition = camPosition;
			cullRotation = camRotation;
		}
	}

	override fn render(t: GfxTarget)
	{
		if (mUseAA) {
			aa.bind(t);
			renderScene(aa.fbo);
			aa.unbindAndDraw(t);
		} else {
			renderScene(t);
		}

		// Draw text
		transform: math.Matrix4x4d;
		t.setMatrixToOrtho(ref transform);
		mat: math.Matrix4x4f;
		mat.setFrom(ref transform);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, ref mat);

		glBindVertexArray(textVbo.vao);
		gfxBitmapTexture.bind();

		glDrawArrays(GL_TRIANGLES, 0, textVbo.num);

		gfxBitmapTexture.unbind();
		glBindVertexArray(0);
	}

	override fn dropControl()
	{
		super.dropControl();
		mCamUp = false;
		mCamFore = false;
		mCamBack = false;
		mCamLeft = false;
		mCamRight = false;
	}

	override fn keyDown(CtlKeyboard, keycode: int)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 32: mCamUp = true; break;
		case 'w': mCamFore = true; break;
		case 's': mCamBack = true; break;
		case 'a': mCamLeft = true; break;
		case 'd': mCamRight = true; break;
		case 'q': printInfo(); break;
		case 'o': mUseAA = !mUseAA; break;
		case 'l': mLockCull = !mLockCull; break;
		default:
		}
	}

	override fn keyUp(CtlKeyboard, keycode: int)
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

	override fn mouseMove(m: CtlMouse, x: int, y: int)
	{
		if (isDragging) {
			mCamHeading += x * -0.003f;
			mCamPitch += y * -0.003f;
		}

		if (mCamPitch < -(PIf/2)) mCamPitch = -(PIf/2);
		if (mCamPitch >  (PIf/2)) mCamPitch =  (PIf/2);
	}

	override fn mouseDown(m: CtlMouse, button: int)
	{
		switch (button) {
		case 1:
			m.setRelativeMode(true);
			isDragging = true;
			break;
		case 4: // Mouse wheel up.
			distance -= 0.1f;
			if (distance < 0.0f) {
				distance = 0.0f;
			}
			break;
		case 5: // Mouse wheel down.
			distance += 0.1f;
			break;
		default:
		}
	}

	override fn mouseUp(m: CtlMouse, button: int)
	{
		if (button == 1) {
			isDragging = false;
			m.setRelativeMode(false);
		}
	}
}
