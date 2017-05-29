// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Code for loading magicavoxel files.
 */
module voxel.loaders.repacker;

import io = watt.io;

import math = charge.math;

import voxel.svo.buddy : sizeToOrder;
import voxel.svo.design;


struct Repacker!(totalLevels: u32)
{
public:
	enum u32 NumLevels = totalLevels;


private:
	mOut: InputBuffer;


public:
	fn setup() u32
	{
		mOut.setup(1);
	}

	fn add(data: void[], start: u32)
	{
		d := cast(u32[])data;
	}
}
