// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module main;

static import examples.gl;
static import power.game;


fn main(args: string[]) int
{
	//g := new examples.gl.Game(args);
	g := new power.game.Game(args);

	return g.loop();
}
