// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.viewer;

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
	GfxAA aa;

	// Rotation stuff.
	bool isDragging;
	float rotationX, rotationY, distance;

	/// Text rendering stuff.
	GfxTexture2D bitmap;
	GfxDrawBuffer textVbo;
	GfxDrawVertexBuilder textBuilder;
	GfxBitmapState textState;


public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		distance = 1.0;


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

	override void render(GfxTarget t)
	{
		aa.bind(t);
		renderScene(aa.fbo);
		aa.unbindAndDraw(t);

		// Draw text
		math.Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(textVbo.vao);
		bitmap.bind();

		glDrawArrays(GL_QUADS, 0, textVbo.num);

		bitmap.unbind();
		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
	}

	override void mouseMove(CtlMouse m, int x, int y)
	{
		if (isDragging) {
			rotationX += x * -0.01f;
			rotationY += y * -0.01f;
		}
	}

	override void mouseDown(CtlMouse m, int button)
	{
		switch (button) {
		case 1:
			m.show(false);
			m.grab(true);
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
			m.show(true);
			m.grab(false);
		}
	}
}
