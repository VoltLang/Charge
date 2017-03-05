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


/**
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
	camHeading, camPitch, distance: f32;
	camRotation: math.Quatf;
	camPosition: math.Point3f;

	camUp, camFore, camBack, camLeft, camRight: bool;

	/// Text rendering stuff.
	textVbo: GfxDrawBuffer;
	textBuilder: GfxDrawVertexBuilder;
	textState: GfxBitmapState;


public:
	this(g: GameSceneManager)
	{
		super(g, Type.Game);
		resetPosition();
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
		io.writefln("\t\tcamHeading = %sf;", cast(f64)camHeading);
		io.writefln("\t\tcamPitch = %sf;", cast(f64)camPitch);
		io.writefln("\t\tcamPosition = math.Point3f.opCall(%sf, %sf, %sf);",
			cast(f64)camPosition.x, cast(f64)camPosition.y,
			cast(f64)camPosition.z);

		x := cast(i32)floor(camPosition.x * 2048);
		y := cast(i32)floor(camPosition.y * 2048);
		z := cast(i32)floor(camPosition.z * 2048);

		io.writefln("%3s %3s %3s", x, y, z);
	}

	fn resetPosition()
	{
		camHeading = -1.182002f;
		camPitch = -0.576000f;
		camPosition = math.Point3f.opCall(-0.282043f, 0.623386f, 0.813192f);
		distance = 1.0;
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
		camRotation = math.Quatf.opCall(camHeading, camPitch, 0.0f);
		sum: math.Vector3f;

		if (camFore != camBack) {
			v: math.Vector3f;
			v.z = camBack ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (camLeft != camRight) {
			v: math.Vector3f;
			v.x = camRight ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (camUp) {
			sum.y += 1;
		}

		if (sum.lengthSqrd() == 0.f) {
			return;
		}

		sum.normalize();
		sum.scale(0.001f);
		camPosition += sum;
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
		mat: math.Matrix4x4f;
		t.setMatrixToOrtho(ref mat);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glBindVertexArray(textVbo.vao);
		gfxBitmapTexture.bind();

		glDrawArrays(GL_TRIANGLES, 0, textVbo.num);

		gfxBitmapTexture.unbind();
		glBindVertexArray(0);
	}

	override fn dropControl()
	{
		super.dropControl();
		camUp = false;
		camFore = false;
		camBack = false;
		camLeft = false;
		camRight = false;
	}

	override fn keyDown(CtlKeyboard, keycode: int)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 32: camUp = true; break;
		case 'w': camFore = true; break;
		case 's': camBack = true; break;
		case 'a': camLeft = true; break;
		case 'd': camRight = true; break;
		case 'q': printInfo(); break;
		case 'p': resetPosition(); break;
		case 'o': mUseAA = !mUseAA; break;
		default:
		}
	}

	override fn keyUp(CtlKeyboard, keycode: int)
	{
		switch (keycode) {
		case 32: camUp = false; break;
		case 'w': camFore = false; break;
		case 's': camBack = false; break;
		case 'a': camLeft = false; break;
		case 'd': camRight = false; break;
		default:
		}
	}

	override fn mouseMove(m: CtlMouse, x: int, y: int)
	{
		if (isDragging) {
			camHeading += x * -0.003f;
			camPitch += y * -0.003f;
		}

		if (camPitch < -(PIf/2)) camPitch = -(PIf/2);
		if (camPitch >  (PIf/2)) camPitch =  (PIf/2);
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
