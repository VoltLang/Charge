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
	text: dg(Keyboard, scope const(char)[]);
	down: dg(Keyboard, int);
	up: dg(Keyboard, int);
}
