// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.inbuilt;

import charge.sys;


fn makeInbuiltTilePng() SysFile
{
	return SysFile.fromImport("power/tile.png", import("power/tile.png"));
}
