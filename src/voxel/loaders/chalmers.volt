// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Code for loading chalmers svo files.
 */
module voxel.loaders.chalmers;

import io = watt.io;

import voxel.svo.buddy : sizeToOrder;
import voxel.gfx.input;


fn isChalmersDag(fileData: void[]) bool
{
	if (fileData.length <= typeid(Header).size) {
		return false;
	}

	h := cast(Header*)fileData.ptr;

	if (!h.check()) {
		return false;
	}

	offset := typeid(Header).size + h.numFrames * typeid(u32).size;
	totalSize := offset + h.dataSizeInU32 * typeid(u32).size;

	if (totalSize > fileData.length) {
		io.writefln("Chalmers dag file does not have enought data.");
		return false;
	}

	return true;
}

enum Magic = 0x00000000cc66f001_u64;

struct Header
{
public:
	id: u64;
	numFrames: u64;
	resolution: u64;
	dataSizeInU32: u64;
	minX: f32;
	minY: f32;
	minZ: f32;
	maxX: f32;
	maxY: f32;
	maxZ: f32;


public:
	fn check() bool
	{
		return id == 0x00000000cc66f001_u64;
	}

	@property fn frames() u32[] {
		offset := typeid(this).size / typeid(u32).size;
		return (cast(u32*)&this)[offset .. offset + numFrames];
	}

	@property fn data() void[] {
		offset := typeid(this).size + numFrames * typeid(u32).size;
		dataSize := dataSizeInU32 * typeid(u32).size;
		return (cast(void*)&this)[offset .. offset + dataSize];
	}
}

final class Loader
{
	fn loadFileFromData(fileData: void[], out c: Create, out frames: u32[], out data: void[]) bool
	{
		h := cast(Header*)fileData.ptr;

		// Setup the state.
		c.xShift = 2;
		c.yShift = 0;
		c.zShift = 1;
		c.numLevels = sizeToOrder(h.resolution);

		// These just reference the input data directly.
		frames = h.frames;
		data = h.data;

		return true;
	}
}
