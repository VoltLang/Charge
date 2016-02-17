// Copyright © 2013-2016, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

static import examples.gl;
static import power.main;


int main(string[] args)
{
	//auto g = new examples.gl.Game(args);
	auto g = new power.main.Game(args);

	return g.c.loop();
}
