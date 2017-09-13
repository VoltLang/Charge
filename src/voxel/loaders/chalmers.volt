// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Code for loading chalmers svo files.
 */
module voxel.loaders.chalmers;

import core.compiler.llvm;

import io = watt.io;

import watt.io.monotonic;

import sys = charge.sys;
import math = charge.math;

import voxel.svo.buddy : sizeToOrder;
import voxel.svo.design;
import voxel.svo.packer;
import voxel.svo.input;


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
private:
	enum ChunkNum : size_t = 1024*1024;
	enum ColorLevels : u32 = 8;

	mPacker: Packer;
	mData: u32[];

	mArr: Input2Cubed[];
	mNum: u32;


public:
	fn loadFileFromData(fileData: void[], out c: Create, out frames: u32[], out data: void[]) bool
	{
		h := cast(Header*)fileData.ptr;
		levels := sizeToOrder(cast(u32)h.resolution);
		totalLevels := levels;

		// Setup the state.
		c.xShift = XShift;
		c.yShift = YShift;
		c.zShift = ZShift;
		c.numLevels = totalLevels;

		mData = cast(u32[])h.data;

		// Convert the array data into a format we know about.
		thenConvert := ticks();
		start := decent(0, h.frames[0], levels);
		nowConvert := ticks();

		// Should always be true.
		assert(start == 0);

		// Setup the packer.
		mPacker.setup(levels, mArr[0 .. mNum]);

		// Reserve the first index.
		ib: InputBuffer;
		ib.setup(1);

		// Only one frame.
		frames = new u32[](1);

		// Compress the 
		thenCompress := ticks();
		frames[0] = mPacker.toBuffer(ib: ref ib, totalLevels: totalLevels, repeat: true);
		nowCompress := ticks();

		// Debug printing.
		calcConvert := convClockFreq(nowConvert - thenConvert, ticksPerSecond, 1_000_00);
		calcCompress := convClockFreq(nowCompress - thenCompress, ticksPerSecond, 1_000_00);
		io.output.writefln("convert %s.%02sms", calcConvert / 100, calcConvert % 100);
		io.output.writefln("compress %s.%02sms", calcCompress / 100, calcCompress % 100);
		io.output.flush();

		// Grab the data.
		data = ib.getData();

		// Free the array afterwards.
		if (mArr.length > 0) {
			sys.cFree(cast(void*)mArr.ptr);
			mArr = null;
		}

		return true;
	}


private:
	final fn decent(morton: u64, index: u32, level: u32) u32
	{
		if (level == 3) {
			return decent2(morton, index);
		}

		morton = morton << 3;

		level--;

		num := newArr();
		d := mData[index];
		tmp: Input2Cubed;

		if (d & 0x01) tmp.set(0, decent(morton | 0, mData[++index], level));
		if (d & 0x02) tmp.set(2, decent(morton | 2, mData[++index], level));
		if (d & 0x04) tmp.set(4, decent(morton | 4, mData[++index], level));
		if (d & 0x08) tmp.set(6, decent(morton | 6, mData[++index], level));
		if (d & 0x10) tmp.set(1, decent(morton | 1, mData[++index], level));
		if (d & 0x20) tmp.set(3, decent(morton | 3, mData[++index], level));
		if (d & 0x40) tmp.set(5, decent(morton | 5, mData[++index], level));
		if (d & 0x80) tmp.set(7, decent(morton | 7, mData[++index], level));

		mArr[num] = tmp;
		return num;
	}

	final fn decent2(morton: u64, index: u32) u32
	{
		morton = morton << 3;

		ensureSpace(mNum + 8u * 8u + 1u);

		num := newArr();
		d := mData[index];
		tmp: Input2Cubed;

		if (d & 0x01) tmp.set(0, decent1(morton | 0, mData[++index]));
		if (d & 0x02) tmp.set(2, decent1(morton | 2, mData[++index]));
		if (d & 0x04) tmp.set(4, decent1(morton | 4, mData[++index]));
		if (d & 0x08) tmp.set(6, decent1(morton | 6, mData[++index]));
		if (d & 0x10) tmp.set(1, decent1(morton | 1, mData[++index]));
		if (d & 0x20) tmp.set(3, decent1(morton | 3, mData[++index]));
		if (d & 0x40) tmp.set(5, decent1(morton | 5, mData[++index]));
		if (d & 0x80) tmp.set(7, decent1(morton | 7, mData[++index]));

		mArr[num] = tmp;
		return num;
	}

	final fn decent1(morton: u64, index: u32) u32
	{
		morton = morton << 3;

		num := newArrUnsafe();
		d := mData[index];
		tmp: Input2Cubed;

		if (d & 0x01) tmp.set(0, decent0(morton | 0, mData[++index]));
		if (d & 0x02) tmp.set(2, decent0(morton | 2, mData[++index]));
		if (d & 0x04) tmp.set(4, decent0(morton | 4, mData[++index]));
		if (d & 0x08) tmp.set(6, decent0(morton | 6, mData[++index]));
		if (d & 0x10) tmp.set(1, decent0(morton | 1, mData[++index]));
		if (d & 0x20) tmp.set(3, decent0(morton | 3, mData[++index]));
		if (d & 0x40) tmp.set(5, decent0(morton | 5, mData[++index]));
		if (d & 0x80) tmp.set(7, decent0(morton | 7, mData[++index]));

		mArr[num] = tmp;
		return num;
	}

	final fn decent0(morton: u64, index: u32) u32
	{
		morton = morton << 3;

		num := newArrUnsafe();
		d := mData[index];

		dst := &mArr[num];
		if (d & 0x01) dst.set(0, getColor(morton | 0));
		if (d & 0x02) dst.set(2, getColor(morton | 2));
		if (d & 0x04) dst.set(4, getColor(morton | 4));
		if (d & 0x08) dst.set(6, getColor(morton | 6));
		if (d & 0x10) dst.set(1, getColor(morton | 1));
		if (d & 0x20) dst.set(3, getColor(morton | 3));
		if (d & 0x40) dst.set(5, getColor(morton | 5));
		if (d & 0x80) dst.set(7, getColor(morton | 7));

		return num;
	}

	global final fn getColor(morton: u64) u32
	{
		v: u32[3];
		math.decode3(morton, out v);
		v[0] = v[0] & 0xf0 | ~v[0] & 0x0f;
		v[1] = v[1] & 0xf0 | ~v[1] & 0x0f;
		v[2] = v[2] & 0xf0 | ~v[2] & 0x0f;

		return 0xff_00_00_00 | v[2] << 16u | v[1] << 8u | v[0] << 0u;
	}


private:
	fn newArr() u32
	{
		ensureSpace(mNum + 1);
		return mNum++;
	}

	fn newArrUnsafe() u32
	{
		return mNum++;
	}

	fn ensureSpace(min: size_t)
	{
		if (min <= mArr.length) {
			return;
		}

		oldSize := mArr.length * typeid(Input2Cubed).size;
		newNum := (mArr.length + ChunkNum);
		newSize := newNum * typeid(Input2Cubed).size;

		ptr := sys.cRealloc(cast(void*)mArr.ptr, newSize);
		__llvm_memset(ptr + oldSize, 0, newSize - oldSize, 8, false);
		mArr = (cast(Input2Cubed*)ptr)[0 .. newNum];
	}
}
