// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.app;

import core = charge.core;
import scene = charge.game.scene;


abstract class App : scene.ManagerApp
{
public:
	this(opts: core.Options)
	{
		super(opts);
	}

	abstract fn showMenu();
	abstract fn showAlignTest();
	abstract fn showVoxelScene();
	abstract fn showVoxelCompare();
}
