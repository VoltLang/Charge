// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.main;

import charge.ctl;
import charge.core;
import charge.game;
import charge.game.scene.background;


class Game : GameSceneManagerApp
{
public:
	this(string[] args)
	{
		// First init core.
		auto opts = new CoreOptions();
		opts.title = "Charged Power";
		opts.width = 1024;
		opts.height = 768;
		super(opts);

		push(new Background(this, opts.width, opts.height,
			"res/tile.png", "res/logo.png"));
		push(new Scene(this));
	}
}


class Scene : GameScene
{
public:
	CtlInput input;

public:
	this(Game g)
	{
		super(g, Type.Menu);

		input = CtlInput.opCall();
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	void down(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close() {}

	override void logic() {}

	override void render() {}

	override void assumeControl()
	{
		input.keyboard.down = down;
	}

	override void dropControl()
	{
		if (input.keyboard.down is down) {
			input.keyboard.down = null;
		}
	}
}
