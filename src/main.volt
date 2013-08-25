// Copyright © 2013, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

import core.stdc.stdio : printf;
import charge.core : chargeCore, Core, CoreOptions;


class Main
{
public:
	this(Core c)
	{
		printf("ctor\n".ptr);
		c.closeDg = close;
		c.renderDg = render;

		return;
	}

	void close()
	{
		printf("close\n".ptr);
		return;
	}

	void render()
	{
		printf("render\n".ptr);
		return;
	}
}

int main()
{
	auto c = chargeCore(new CoreOptions());
	auto m = new Main(c);

	return c.loop();
}
