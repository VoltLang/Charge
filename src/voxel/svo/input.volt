// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.input;

import core.compiler.llvm;

import io = watt.io;

import math = charge.math;

import voxel.svo.design;
import voxel.svo.buddy;


struct Input2Cubed = mixin InputDefinition!(1);
struct Input4Cubed = mixin InputDefinition!(2);
struct Input8Cubed = mixin InputDefinition!(3);

//! Select the default input buffer.
alias InputBuffer = LinearBuffer;

//! Linear adding comrpessing buffer.
struct LinearBuffer = mixin CompressingBuffer!(LinearAdder);

//! Buddy based adding comrpessing buffer.
struct BuddyBuffer = mixin CompressingBuffer!(BuddyAdder);

//! Buddy allocator for the InputBuffer.
struct InputBuddy = mixin BuddyDefinition!(5u, 16u, u32);

/*!
 * Helper struct that holds common code to compress InputXCubed data.
 */
struct CompressingBuffer!(Base)
{
public:
	enum u32 BitsPerFlag = 16u;
	enum u32 FlagsNum2 = FlagsNum2Cubed;
	enum u32 FlagsNum4 = FlagsNum2And4;
	enum u32 FlagsNum8 = FlagsNum2And8;
	enum u32 FlagsNum2And4 = FlagsNum2Cubed + FlagsNum4Cubed;
	enum u32 FlagsNum2And8 = FlagsNum2Cubed + FlagsNum8Cubed;

	enum u32 MaxNum2 = FlagsNum2Cubed + Input2Cubed.ElementsNum;
	enum u32 MaxNum4 = MaxNum2And4;
	enum u32 MaxNum2And4 = FlagsNum2Cubed + Input2Cubed.ElementsNum +
	                       FlagsNum4Cubed + Input4Cubed.ElementsNum;
	enum u32 MaxNum2And8 = FlagsNum2Cubed + Input2Cubed.ElementsNum +
	                       FlagsNum8Cubed + Input8Cubed.ElementsNum;


private:
	enum u32 FlagsNum2Cubed = 1u;
	enum u32 FlagsNum4Cubed = Input4Cubed.ElementsNum / BitsPerFlag;
	enum u32 FlagsNum8Cubed = Input8Cubed.ElementsNum / BitsPerFlag;


public:
	base: Base;


public:
	fn setup(numReserved: u32)
	{
		base.setup(numReserved);
	}

	fn getData() void[]
	{
		return base.getData();
	}

	/*!
	 * Adds a Input and does a very simple compression suited
	 * for rendering on the GPU.
	 */
	fn compressAndAdd(ref box2: Input2Cubed) u32
	{
		// Reserve the start of the packed values for flags.
		num := FlagsNum2Cubed;
		packed: u32[MaxNum2];

		num = add(packed, ref box2, num);

		return base.add(packed[0 .. num]);
	}

	/*!
	 * Adds a Input and does a very simple compression suited
	 * for rendering on the GPU.
	 */
	fn compressAndAdd(ref box4: Input4Cubed) u32
	{
		// Reserve the start of the packed values for flags.
		num := FlagsNum4;
		packed: u32[MaxNum4];

		num = add(packed, ref box4, num);

		return base.add(packed[0 .. num]);
	}

	/*!
	 * Adds a Input and does a very simple compression suited
	 * for rendering on the GPU.
	 */
	fn compressAndAdd(ref box2: Input2Cubed, ref box4: Input4Cubed) u32
	{
		// Reserve the start of the packed values for flags.
		num := FlagsNum2And4;
		packed: u32[MaxNum2And4];

		num = add(packed, ref box2, num);
		num = add(packed, ref box4, num);

		return base.add(packed[0 .. num]);
	}

	/*!
	 * Adds a Input and does a very simple compression suited
	 * for rendering on the GPU.
	 */
	fn compressAndAdd(ref box2: Input2Cubed, ref box8: Input8Cubed) u32
	{
		// Reserve the start of the packed values for flags.
		num := FlagsNum2And8;
		packed: u32[MaxNum2And8];

		num = add(packed, ref box2, num);
		num = add(packed, ref box8, num);

		return base.add(packed[0 .. num]);
	}


private:
	static fn add(packed: scope u32[], ref box2: Input2Cubed, num: u32) u32
	{
		packed[0] = (num << 16u) | box2.u.flags[0];

		foreach (i; 0 .. Input2Cubed.ElementsNum) {
			if (box2.getBit(i)) {
				packed[num++] = box2.data[i];
			}
		}

		return num;
	}

	static fn add(packed: scope u32[], ref box4: Input4Cubed, num: u32) u32
	{
		foreach (i; 0u .. Input4Cubed.ElementsNum) {

			flagIndex := (i / BitsPerFlag) + FlagsNum2Cubed;

			// Write the offset for the values here.
			if (i % BitsPerFlag == 0) {
				packed[flagIndex] |= num << BitsPerFlag;
			}

			if (!box4.getBit(i)) {
				continue;
			}

			// Add the value to the packed struct.
			packed[flagIndex] |= 1 << (i % BitsPerFlag);
			packed[num++] = box4.data[i];
		}

		return num;
	}

	static fn add(packed: scope  u32[], ref box8: Input8Cubed, num: u32) u32
	{
		foreach (i; 0u .. Input8Cubed.ElementsNum) {

			flagIndex := (i / BitsPerFlag) + FlagsNum2Cubed;

			// Write the offset for the values here.
			if (i % BitsPerFlag == 0) {
				packed[flagIndex] |= num << BitsPerFlag;
			}

			if (!box8.getBit(i)) {
				continue;
			}

			// Add the value to the packed struct.
			packed[flagIndex] |= 1 << (i % BitsPerFlag);
			packed[num++] = box8.data[i];
		}

		return num;
	}
}

//! Linear buffer for filling up voxel data.
struct LinearAdder
{
private:
	mMap: u32[const(u32)[]];
	mData: u32[];
	mNumData: u32;


public:
	fn setup(numReserved: u32)
	{
		mNumData = numReserved;
		mData = new u32[](InputBuddy.numBitsInOrder(0));
	}

	/*!
	 * Returns the entire data buffer as void array.
	 */
	fn getData() void[]
	{
		return cast(void[])(mData[0 .. mNumData]);
	}

	/*!
	 * Small helper to add a single u32 value.
	 */
	fn add(v: u32) u32
	{
		buf: u32[1]; buf[0] = v;
		return add(buf[..]);
	}

	/*!
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
			return *r;
		}

		// Grab the next free memory from the buffer.
		pos := mNumData;
		mNumData += cast(u32)data.length;
		internal := mData[pos .. pos + data.length];
		internal[..] = data;
		mMap[internal] = pos;

		return pos;
	}
}

/*!
 * Caching input buffer to build SVOs, is more designed for live updating
 * then space size, so wastes memory.
 */
struct BuddyAdder
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
	mMaxSize: u32;


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

	/*!
	 * Returns the entire data buffer as void array.
	 */
	fn getData() void[]
	{
		return cast(void[])mData[0 .. mMaxSize];
	}

	/*!
	 * Small helper to add a single u32 value.
	 */
	fn add(v: u32) u32
	{
		buf: u32[1]; buf[0] = v;
		return add(buf[..]);
	}

	/*!
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
		internal[..] = data;
		e: Entry = { pos, order };
		mMap[internal] = e;

		endSize := pos + cast(u32)data.length;
		if (endSize > mMaxSize) {
			mMaxSize = endSize;
		}

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
	static fn indexOf(x: u32, y: u32, z: u32) u32
	{
		x %= Size; y %= Size; z %= Size;
		return x * XStride + y * YStride + z * ZStride;
	}

	fn getBit(index: u32) bool
	{
		findex := index / FlagsNumBits;
		fshift := index % FlagsNumBits;
		return (u.flags[findex] & cast(FlagsType)(1 << fshift)) != 0;
	}

	fn set(index: u32, d: u32)
	{
		data[index] = d;
		findex := index / FlagsNumBits;
		fshift := index % FlagsNumBits;
		u.flags[findex] |= cast(FlagsType)(1 << fshift);
	}

	fn set(x: u32, y: u32, z: u32, d: u32)
	{
		set(indexOf(x, y, z), d);
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
