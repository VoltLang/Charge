// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Scene base class and SceneManager interface.
 */
module charge.game.scene.simple;

import charge.ctl;
import charge.gfx;
import charge.game.scene.scene;


/**
 * Helper that, implements all of the functions on Scene.
 */
abstract class SimpleScene : Scene
{
protected:
	CtlInput mInput;


public:
	this(SceneManager sm, Type type)
	{
		super(sm, type);
		mInput = CtlInput.opCall();
	}

	override void close() {}
	override void logic() {}
	override void render(GfxTarget t) {}

	void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m) {}
	void keyUp(CtlKeyboard, int) {}

	void mouseMove(CtlMouse, int, int) {}
	void mouseDown(CtlMouse, int) {}
	void mouseUp(CtlMouse, int) {}

	override void assumeControl()
	{
		mInput.keyboard.down = keyDown;
		mInput.keyboard.up = keyUp;
		mInput.mouse.move = mouseMove;
		mInput.mouse.down = mouseDown;
		mInput.mouse.up = mouseUp;
	}

	override void dropControl()
	{
		if (mInput.keyboard.down is keyDown) {
			mInput.keyboard.down = null;
		}
		if (mInput.keyboard.up is keyUp) {
			mInput.keyboard.up = null;
		}
		if (mInput.mouse.move is mouseMove) {
			mInput.mouse.move = null;
		}
		if (mInput.mouse.down is mouseDown) {
			mInput.mouse.down = null;
		}
		if (mInput.mouse.up is mouseUp) {
			mInput.mouse.up = null;
		}
	}
}
