// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.inbuilt;

import sys = charge.sys;


fn makeInbuiltTilePng() sys.File
{
	return sys.File.fromImport("power/tile.png", import("power/tile.png"));
}
