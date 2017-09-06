// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.app;

import game = charge.game;

import charge.core;


abstract class App : game.SceneManagerApp
{
public:
	this(opts: CoreOptions)
	{
		super(opts);
	}

	abstract fn showMenu();
	abstract fn showVoxelTest();
	abstract fn showAlignTest();
}
