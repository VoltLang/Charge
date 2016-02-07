// Copyright © 2013-2016, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

static import examples.gl;


int main()
{
	auto g = new examples.gl.Game();

	return g.c.loop();
}
