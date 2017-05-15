// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Common input code for renderers.
 */
module voxel.gfx.input;

import math = charge.math;


struct Create
{
	xShift, yShift, zShift: u32;
	numLevels: u32;
}

struct Draw
{
	camMVP: math.Matrix4x4d;
	cullMVP: math.Matrix4x4d;
	camPos: math.Point3f; pad0: f32;
	cullPos: math.Point3f; pad1: f32;
	frame, pad2, pad3, pad4: u32;
}
