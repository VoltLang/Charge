// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module power.inbuilt;

import sys = charge.sys;


fn makeInbuiltTilePng() sys.File
{
	return sys.File.fromImport("power/tile.png", import("power/tile.png"));
}
