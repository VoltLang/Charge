// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo;

import core.c.stdio;
import core.c.stdlib;

import io = watt.io;

import charge.core;
import voxel.svo.buddy;

fn test()
{
	t: Input1;
	ib: InputBuffer;
	ib.setup();

	t.set(0, 1, 0, 0xff);
	t.dumpBits();
	printf("%i\n", ib.add([0, 0, 0, 0]));
	printf("%i\n", ib.add([0, 0, 0, 0]));
	printf("%i\n", ib.add([0, 0, 0, 1]));
	printf("%i\n", ib.add([0, 0, 0, 0]));
}

enum NumDim = 3;
enum XShift = 0;
enum YShift = 1;
enum ZShift = 2;

struct InputBuddy = mixin BuddyDefinition!(5u, 10u, u32);
struct Input1 = mixin InputDefinition!(1);
struct Input2 = mixin InputDefinition!(2);
struct Input3 = mixin InputDefinition!(3);

struct InputBuffer
{
private:
	alias Key = const(u8)[];

	struct Entry
	{
		u32 pos;
		u32 order;
	}


private:
	mMap: Entry[Key];
	mBuddy: InputBuddy;


public:
	fn setup()
	{
		mBuddy.setup();
	}

	/**
	 * Adds data into the buffer and returns the index to it.
	 *
	 * If there is data inside of the buffer that matches the
	 * contents, it will point to it instead.
	 */
	fn add(data: const(u8)[]) u32
	{
		// Is there a cache of the data.
		r := data in mMap;
		if (r !is null) {
			return r.pos;
		}

		// Buddy only tracks per u32 not per byte.
		assert(data.length % 4 == 0);
		size := data.length / 4;

		// Grab memory from the buddy allocator.
		order := sizeToOrder(size);
		pos := cast(u32)mBuddy.alloc(order) * (1u << order);
		e: Entry = { pos, order };
		mMap[data] = e;
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
	fn set(x: uint, y: uint, z: uint, d: uint)
	{
		x %= Size; y %= Size; z %= Size;

		index := x * XStride + y * YStride + z * ZStride;
		data[index] = d;
		findex := index / FlagsNumBits;
		fshift := index % FlagsNumBits;
		u.flags[findex] |= cast(FlagsType)(1 << fshift);
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
