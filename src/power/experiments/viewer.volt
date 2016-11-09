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
	bool mUseAA;
	GfxAA aa;

	// Rotation stuff.
	bool isDragging;
	float camHeading, camPitch, distance;
	camRotation: math.Quatf;
	camPosition: math.Point3f;

	bool camUp, camFore, camBack, camLeft, camRight;

	/// Text rendering stuff.
	GfxTexture2D bitmap;
	GfxDrawBuffer textVbo;
	GfxDrawVertexBuilder textBuilder;
	GfxBitmapState textState;


public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		camHeading = 0.f;
		camPitch = 0.f;
		camPosition = math.Point3f.opCall(0.20f, 0.20f, 1.0f);
		distance = 1.0;
		mUseAA = false;

		bitmap = GfxTexture2D.load(Pool.opCall(), "res/font.png");

		textState.glyphWidth = cast(int)bitmap.width / 16;
		textState.glyphHeight = cast(int)bitmap.height / 16;
		textState.offX = 16;
		textState.offY = 16;

		text := "Info";
		textBuilder = new GfxDrawVertexBuilder(0);
		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo = GfxDrawBuffer.make("power/exp/text", textBuilder);

		updateText("Info:");
	}

	void renderScene(GfxTarget t)
	{

	}

	void updateText(string text)
	{
		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo.update(textBuilder);
	}

	void printInfo()
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

	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close()
	{
		aa.breakApart();
		if (textVbo !is null) { textVbo.decRef(); textVbo = null; }
	}

	override void logic()
	{
		camRotation = math.Quatf.opCall(camHeading, camPitch, 0.0f);
		math.Vector3f sum;

		if (camFore != camBack) {
			math.Vector3f v;
			v.z = camBack ? 1.0f : -1.0f;
			sum += camRotation * v;
		}

		if (camLeft != camRight) {
			math.Vector3f v;
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

	override void render(GfxTarget t)
	{
		if (mUseAA) {
			aa.bind(t);
			renderScene(aa.fbo);
			aa.unbindAndDraw(t);
		} else {
			renderScene(t);
		}

		// Draw text
		math.Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(textVbo.vao);
		bitmap.bind();

		glDrawArrays(GL_TRIANGLES, 0, textVbo.num);

		bitmap.unbind();
		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void dropControl()
	{
		super.dropControl();
		camUp = false;
		camFore = false;
		camBack = false;
		camLeft = false;
		camRight = false;
	}

	override void keyDown(CtlKeyboard, int keycode, dchar, scope const(char)[] m)
	{
		switch (keycode) {
		case 27: mManager.closeMe(this); break;
		case 32: camUp = true; break;
		case 'w': camFore = true; break;
		case 's': camBack = true; break;
		case 'a': camLeft = true; break;
		case 'd': camRight = true; break;
		case 'q': printInfo(); break;
		default:
		}
	}

	override void keyUp(CtlKeyboard, int keycode)
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

	override void mouseMove(CtlMouse m, int x, int y)
	{
		if (isDragging) {
			camHeading += x * -0.003f;
			camPitch += y * -0.003f;
		}

		if (camPitch < -PIf) camPitch = -PIf;
		if (camPitch >  PIf) camPitch =  PIf;
	}

	override void mouseDown(CtlMouse m, int button)
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

	override void mouseUp(CtlMouse m, int button)
	{
		if (button == 1) {
			isDragging = false;
			m.setRelativeMode(false);
		}
	}
}
