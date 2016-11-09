// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Keyboard.
 */
module charge.ctl.keyboard;

import charge.ctl.device;


class Keyboard : Device
{
public:
	void delegate(Keyboard, int, dchar, scope const(char)[]) down;
	void delegate(Keyboard, int) up;
}
