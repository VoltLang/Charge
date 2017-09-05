// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.app;

import charge.core;
import charge.game;


abstract class App : GameSceneManagerApp
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
