// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
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
