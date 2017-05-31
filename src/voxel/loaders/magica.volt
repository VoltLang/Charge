// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Code for loading magicavoxel files.
 */
module voxel.loaders.magica;

import io = watt.io;

import watt.io.file;
import watt.algorithm;

import math = charge.math;
import voxel.svo;
import voxel.svo.buddy : nextHighestPowerOfTwo, sizeToOrder;


fn isMagicaFile(fileData: void[]) bool
{
	if (fileData.length <= typeid(Header).size) {
		return false;
	}

	h := cast(Header*)fileData.ptr;

	return h.check();
}


final class Loader
{
private:
	mPacker: Packer;
	mLevels: u32;


public:
	this()
	{

	}

	fn loadFileFromData(fileData: void[], out frames: u32[], out data: void[]) bool
	{
		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Load parse the file.
		if (!loadFileFromData(fileData)) {
			return false;
		}

		// Only one frame.
		frames = new u32[](1);
		frames[0] = toBuffer(ib: ref ib, totalLevels: 11, repeat: true);

		// Grab the data.
		data = ib.getData();

		return true;
	}

	fn loadFileFromData(data: void[]) bool
	{
		ptr := cast(ubyte*)data.ptr;
		end := cast(ubyte*)data.ptr + data.length;
		h := *cast(Header*)ptr; ptr += typeid(Header).size;

		x, y, z: u32;
		voxels: Voxel[];
		numVoxels: u32;
		numModels: u32 = 1; // Defualt
		colors := defaultColors;

		while (cast(size_t)ptr < cast(size_t)end) {
			c := cast(Chunk*)ptr; ptr += typeid(Chunk).size;

			switch (c.id[..]) {
			case "PACK":
				u32Ptr := cast(u32*)ptr;
				numModels = u32Ptr[0];
				break;
			case "SIZE":
				u32Ptr := cast(u32*)ptr;
				x = u32Ptr[0];
				z = u32Ptr[1]; // Magica has Z as gravity.
				y = u32Ptr[2];
				break;
			case "XYZI":
				numVoxels = *cast(u32*)ptr;
				voxels = (cast(Voxel*)(ptr + 4))[0 .. numVoxels];
				break;
			case "RGBA":
				colors = (cast(math.Color4b*)ptr)[0 .. 256];
				break;
			default:
			}
			ptr = ptr + c.chunkSize;
		}

		if (numModels != 1) {
			io.writefln("invalid number of models '%s' (no animations).", numModels);
			return false;
		}

		if (x <   2 || y <   2 || z <   2 ||
		    x > 256 || y > 256 || z > 256) {
			io.writefln("invalid magica voxel dimensions (%s, %s, %s)", x, z, y);
			return false;
		}

		size := max(nextHighestPowerOfTwo(x), 
		            max(nextHighestPowerOfTwo(y),
		                nextHighestPowerOfTwo(z)));
		mLevels = sizeToOrder(size);

		// This helps use prune voxels that have neighbours set.
		p := new Pruner;
		foreach (v; voxels) {
			p.add(v.x, v.z, v.y);
		}

		// Setup the packer.
		mPacker.setup(mLevels);

		added: u32; pruned: u32;
		foreach (v; voxels) {
			if (p.shouldPrune(v.x, v.z, v.y)) {
				pruned++;
				continue;
			}
			added++;

			color := *cast(u32*)&colors[v.c-1];
			mPacker.add(v.x, v.z, v.y, color);
		}

		return true;
	}

	fn toBuffer(ref ib: InputBuffer, totalLevels: u32, repeat: bool) u32
	{
		ret := mPacker.toBuffer(ref ib);

		foreach (i; 0 .. totalLevels - mLevels) {
			tmp: Input2Cubed;
			tmp.set(0, 0, 0, ret);
			if (repeat) {
				tmp.set(0, 0, 1, ret);
				tmp.set(1, 0, 1, ret);
				tmp.set(1, 0, 0, ret);
			}
			ret = ib.compressAndAdd(ref tmp);
		}

		return ret;
	}
}


private:

enum Magic   = 0x20584f56;
enum Version = 0x00000096;

struct Header
{
public:
	char[4] magicStr;
	char[4] verStr;


public:
	fn check() bool
	{
		return magic == 0x20584f56 && ver == 0x00000096;
	}

	@property fn magic() u32 { return *cast(u32*)magicStr.ptr; }
	@property fn ver() u32 { return *cast(u32*)verStr.ptr; }
}

struct Chunk
{
	char[4] id;
	u32 chunkSize;
	u32 childSize;
}

struct Voxel
{
	u8 x;
	u8 y;
	u8 z;
	u8 c;
}

struct Pruner
{
private:
	enum u32 PaddedSize = 256u + 2u;
	enum u32 XStride = 1u;
	enum u32 YStride = XStride * PaddedSize;
	enum u32 ZStride = YStride * PaddedSize;
	enum u32 Bits = (ZStride * PaddedSize);
	enum u32 Elems = Bits / 32u + 4u;


public:
	bits: u32[Elems];


public:
	fn add(x: u8, y: u8, z: u8)
	{
		set(getIndex(x, y, z));
	}

	fn shouldPrune(x: u8, y: u8, z: u8) bool
	{

		index := getIndex(x, y, z);
		ret := cast(bool)(
			get(index + XStride) &
			get(index - XStride) &
			get(index + YStride) &
			get(index - YStride) &
			get(index + ZStride) &
			get(index - ZStride));
		return ret;
	}


private:
	fn getIndex(x: u8, y: u8, z: u8) u32
	{
		return (x + 1u) * XStride + (y + 1u) * YStride + (z + 1u) * ZStride;
	}

	fn set(index: u32)
	{
		findex := index / 32u;
		bindex := index % 32u;
		bits[findex] |= (1u << bindex);
	}

	fn get(index: u32) u32
	{
		findex := index / 32u;
		bindex := index % 32u;
		return (bits[findex] & (1u << bindex)) != 0;
	}
}

global math.Color4b[] defaultColors = [
	{255, 255, 255, 255}, {255, 255, 204, 255}, {255, 255, 153, 255},
	{255, 255, 102, 255}, {255, 255,  51, 255}, {255, 255,   0, 255},
	{255, 204, 255, 255}, {255, 204, 204, 255}, {255, 204, 153, 255},
	{255, 204, 102, 255}, {255, 204,  51, 255}, {255, 204,   0, 255},
	{255, 153, 255, 255}, {255, 153, 204, 255}, {255, 153, 153, 255},
	{255, 153, 102, 255}, {255, 153,  51, 255}, {255, 153,   0, 255},
	{255, 102, 255, 255}, {255, 102, 204, 255}, {255, 102, 153, 255},
	{255, 102, 102, 255}, {255, 102,  51, 255}, {255, 102,   0, 255},
	{255,  51, 255, 255}, {255,  51, 204, 255}, {255,  51, 153, 255},
	{255,  51, 102, 255}, {255,  51,  51, 255}, {255,  51,   0, 255},
	{255,   0, 255, 255}, {255,   0, 204, 255}, {255,   0, 153, 255},
	{255,   0, 102, 255}, {255,   0,  51, 255}, {255,   0,   0, 255},
	{204, 255, 255, 255}, {204, 255, 204, 255}, {204, 255, 153, 255},
	{204, 255, 102, 255}, {204, 255,  51, 255}, {204, 255,   0, 255},
	{204, 204, 255, 255}, {204, 204, 204, 255}, {204, 204, 153, 255},
	{204, 204, 102, 255}, {204, 204,  51, 255}, {204, 204,   0, 255},
	{204, 153, 255, 255}, {204, 153, 204, 255}, {204, 153, 153, 255},
	{204, 153, 102, 255}, {204, 153,  51, 255}, {204, 153,   0, 255},
	{204, 102, 255, 255}, {204, 102, 204, 255}, {204, 102, 153, 255},
	{204, 102, 102, 255}, {204, 102,  51, 255}, {204, 102,   0, 255},
	{204,  51, 255, 255}, {204,  51, 204, 255}, {204,  51, 153, 255},
	{204,  51, 102, 255}, {204,  51,  51, 255}, {204,  51,   0, 255},
	{204,   0, 255, 255}, {204,   0, 204, 255}, {204,   0, 153, 255},
	{204,   0, 102, 255}, {204,   0,  51, 255}, {204,   0,   0, 255},
	{153, 255, 255, 255}, {153, 255, 204, 255}, {153, 255, 153, 255},
	{153, 255, 102, 255}, {153, 255,  51, 255}, {153, 255,   0, 255},
	{153, 204, 255, 255}, {153, 204, 204, 255}, {153, 204, 153, 255},
	{153, 204, 102, 255}, {153, 204,  51, 255}, {153, 204,   0, 255},
	{153, 153, 255, 255}, {153, 153, 204, 255}, {153, 153, 153, 255},
	{153, 153, 102, 255}, {153, 153,  51, 255}, {153, 153,   0, 255},
	{153, 102, 255, 255}, {153, 102, 204, 255}, {153, 102, 153, 255},
	{153, 102, 102, 255}, {153, 102,  51, 255}, {153, 102,   0, 255},
	{153,  51, 255, 255}, {153,  51, 204, 255}, {153,  51, 153, 255},
	{153,  51, 102, 255}, {153,  51,  51, 255}, {153,  51,   0, 255},
	{153,   0, 255, 255}, {153,   0, 204, 255}, {153,   0, 153, 255},
	{153,   0, 102, 255}, {153,   0,  51, 255}, {153,   0,   0, 255},
	{102, 255, 255, 255}, {102, 255, 204, 255}, {102, 255, 153, 255},
	{102, 255, 102, 255}, {102, 255,  51, 255}, {102, 255,   0, 255},
	{102, 204, 255, 255}, {102, 204, 204, 255}, {102, 204, 153, 255},
	{102, 204, 102, 255}, {102, 204,  51, 255}, {102, 204,   0, 255},
	{102, 153, 255, 255}, {102, 153, 204, 255}, {102, 153, 153, 255},
	{102, 153, 102, 255}, {102, 153,  51, 255}, {102, 153,   0, 255},
	{102, 102, 255, 255}, {102, 102, 204, 255}, {102, 102, 153, 255},
	{102, 102, 102, 255}, {102, 102,  51, 255}, {102, 102,   0, 255},
	{102,  51, 255, 255}, {102,  51, 204, 255}, {102,  51, 153, 255},
	{102,  51, 102, 255}, {102,  51,  51, 255}, {102,  51,   0, 255},
	{102,   0, 255, 255}, {102,   0, 204, 255}, {102,   0, 153, 255},
	{102,   0, 102, 255}, {102,   0,  51, 255}, {102,   0,   0, 255},
	{ 51, 255, 255, 255}, { 51, 255, 204, 255}, { 51, 255, 153, 255},
	{ 51, 255, 102, 255}, { 51, 255,  51, 255}, { 51, 255,   0, 255},
	{ 51, 204, 255, 255}, { 51, 204, 204, 255}, { 51, 204, 153, 255},
	{ 51, 204, 102, 255}, { 51, 204,  51, 255}, { 51, 204,   0, 255},
	{ 51, 153, 255, 255}, { 51, 153, 204, 255}, { 51, 153, 153, 255},
	{ 51, 153, 102, 255}, { 51, 153,  51, 255}, { 51, 153,   0, 255},
	{ 51, 102, 255, 255}, { 51, 102, 204, 255}, { 51, 102, 153, 255},
	{ 51, 102, 102, 255}, { 51, 102,  51, 255}, { 51, 102,   0, 255},
	{ 51,  51, 255, 255}, { 51,  51, 204, 255}, { 51,  51, 153, 255},
	{ 51,  51, 102, 255}, { 51,  51,  51, 255}, { 51,  51,   0, 255},
	{ 51,   0, 255, 255}, { 51,   0, 204, 255}, { 51,   0, 153, 255},
	{ 51,   0, 102, 255}, { 51,   0,  51, 255}, { 51,   0,   0, 255},
	{  0, 255, 255, 255}, {  0, 255, 204, 255}, {  0, 255, 153, 255},
	{  0, 255, 102, 255}, {  0, 255,  51, 255}, {  0, 255,   0, 255},
	{  0, 204, 255, 255}, {  0, 204, 204, 255}, {  0, 204, 153, 255},
	{  0, 204, 102, 255}, {  0, 204,  51, 255}, {  0, 204,   0, 255},
	{  0, 153, 255, 255}, {  0, 153, 204, 255}, {  0, 153, 153, 255},
	{  0, 153, 102, 255}, {  0, 153,  51, 255}, {  0, 153,   0, 255},
	{  0, 102, 255, 255}, {  0, 102, 204, 255}, {  0, 102, 153, 255},
	{  0, 102, 102, 255}, {  0, 102,  51, 255}, {  0, 102,   0, 255},
	{  0,  51, 255, 255}, {  0,  51, 204, 255}, {  0,  51, 153, 255},
	{  0,  51, 102, 255}, {  0,  51,  51, 255}, {  0,  51,   0, 255},
	{  0,   0, 255, 255}, {  0,   0, 204, 255}, {  0,   0, 153, 255},
	{  0,   0, 102, 255}, {  0,   0,  51, 255}, {238,   0,   0, 255},
	{221,   0,   0, 255}, {187,   0,   0, 255}, {170,   0,   0, 255},
	{136,   0,   0, 255}, {119,   0,   0, 255}, { 85,   0,   0, 255},
	{ 68,   0,   0, 255}, { 34,   0,   0, 255}, { 17,   0,   0, 255},
	{  0, 238,   0, 255}, {  0, 221,   0, 255}, {  0, 187,   0, 255},
	{  0, 170,   0, 255}, {  0, 136,   0, 255}, {  0, 119,   0, 255},
	{  0,  85,   0, 255}, {  0,  68,   0, 255}, {  0,  34,   0, 255},
	{  0,  17,   0, 255}, {  0,   0, 238, 255}, {  0,   0, 221, 255},
	{  0,   0, 187, 255}, {  0,   0, 170, 255}, {  0,   0, 136, 255},
	{  0,   0, 119, 255}, {  0,   0,  85, 255}, {  0,   0,  68, 255},
	{  0,   0,  34, 255}, {  0,   0,  17, 255}, {238, 238, 238, 255},
	{221, 221, 221, 255}, {187, 187, 187, 255}, {170, 170, 170, 255},
	{136, 136, 136, 255}, {119, 119, 119, 255}, { 85,  85,  85, 255},
	{ 68,  68,  68, 255}, { 34,  34,  34, 255}, { 17,  17,  17, 255}
];
