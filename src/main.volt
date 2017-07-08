// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

static import examples.gl;
static import power.game;
static import ohmd.game;


fn main(args: string[]) int
{
	//g := new examples.gl.Game(args);
	//g := new power.game.Game(args);
	g := new ohmd.game.Game(args);

	return g.loop();
}
