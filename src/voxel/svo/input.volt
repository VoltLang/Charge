// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.input;

import core.compiler.llvm;

import io = watt.io;

import voxel.svo.design;
import voxel.svo.buddy;


struct Input2Cubed = mixin InputDefinition!(1);
struct Input4Cubed = mixin InputDefinition!(2);
struct Input8Cubed = mixin InputDefinition!(3);

/// Buddy allocator for the InputBuffer.
struct InputBuddy = mixin BuddyDefinition!(5u, 16u, u32);

/**
 * Caching input buffer to build SVOs, is more designed for live updating
 * then space size, so wastes memory.
 */
struct InputBuffer
{
private:
	struct Entry
	{
		u32 pos;
		u32 order;
	}


private:
	mMap: Entry[const(u32)[]];
	mBuddy: InputBuddy;
	mData: u32[];


public:
	fn setup(numReserved: u32)
	{
		mBuddy.setup();

		// Reserve the first n u32s.
		foreach (i; 0 .. numReserved) {
			reserved := mBuddy.alloc(0);
			assert(reserved == i);
		}

		mData = new u32[](InputBuddy.numBitsInOrder(0));
	}

	/**
	 * Returns the entire data buffer as void array.
	 */
	fn getData() void[]
	{
		return cast(void[])mData;
	}

	/**
	 * Adds a Input and does a very simple compression suited 
	 */
	fn compressAndAdd(ref box: Input2Cubed) u32
	{
		buf: u32[Input2Cubed.ElementsNum + 1];
		count: u32;

		buf[count++] = box.u.flags[0];

		foreach (i; 0 .. Input2Cubed.ElementsNum) {
			if (box.getBit(i)) {
				buf[count++] = box.data[i];
			}
		}

		return add(buf[0 .. count]);
	}

	/**
	 * Small helper to add a single u32 value.
	 */
	fn add(v: u32) u32
	{
		buf: u32[1]; buf[0] = v;
		return add(buf[..]);
	}

	/**
	 * Adds data into the buffer and returns the index to it.
	 *
	 * If there is data inside of the buffer that matches the
	 * contents, it will point to it instead.
	 */
	fn add(data: scope const(u32)[]) u32
	{
		// Is there a cache of the data.
		r := data in mMap;
		if (r !is null) {
			return r.pos;
		}

		// Grab memory from the buddy allocator.
		order := sizeToOrder(data.length);
		pos := cast(u32)mBuddy.alloc(order) * (1u << order);
		internal := mData[pos .. pos + data.length];
		internal[] = data;
		e: Entry = { pos, order };
		mMap[internal] = e;
		return pos;
	}
}

struct InputDefinition!(MAX: u32)
{
public:
	enum u32 Pow = MAX;
	enum u32 Size = 1u << Pow;
	alias ElementsType = u32;
	enum u32 ElementsNum = 1u << (Pow * NumDim);
	enum u32 XStride = 1u << (Pow * XShift);
	enum u32 YStride = 1u << (Pow * YShift);
	enum u32 ZStride = 1u << (Pow * ZShift);
	alias FlagsType = u8;
	enum u32 FlagsNumBits = typeid(FlagsType).size * 8u;
	enum u32 FlagsNum = ElementsNum / FlagsNumBits;

	union U {
		_pad: u32;
		flags: FlagsType[FlagsNum];
	}


public:
	u: U;
	data: ElementsType[ElementsNum];


public:
	fn getBit(index: u32) bool
	{
		findex := index / FlagsNumBits;
		fshift := index % FlagsNumBits;
		return (u.flags[findex] & cast(FlagsType)(1 << fshift)) != 0;
	}

	fn set(x: u32, y: u32, z: u32, d: u32)
	{
		x %= Size; y %= Size; z %= Size;

		index := x * XStride + y * YStride + z * ZStride;
		data[index] = d;
		findex := index / FlagsNumBits;
		fshift := index % FlagsNumBits;
		u.flags[findex] |= cast(FlagsType)(1 << fshift);
	}

	fn reset()
	{
		__llvm_memset(cast(void*)&this, 0, typeid(this).size, 0, false);
	}

	fn dumpBits()
	{
		ptr := cast(u32*)&this;
		size := typeid(this).size / 4;
		foreach (bits; ptr[0 .. size]) {
			io.writefln("0x%08x", bits);
		}
		io.output.flush();
	}
}
