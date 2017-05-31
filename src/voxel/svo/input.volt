// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.input;

import core.compiler.llvm;

import math = charge.math;

import io = watt.io;

import voxel.svo.design;
import voxel.svo.buddy;


struct Input2Cubed = mixin InputDefinition!(1);
struct Input4Cubed = mixin InputDefinition!(2);
struct Input8Cubed = mixin InputDefinition!(3);

/// Select the default input buffer.
alias InputBuffer = LinearBuffer;

/// Linear adding comrpessing buffer.
struct LinearBuffer = mixin CompressingBuffer!(LinearAdder);

/// Buddy based adding comrpessing buffer.
struct BuddyBuffer = mixin CompressingBuffer!(BuddyAdder);

/// Buddy allocator for the InputBuffer.
struct InputBuddy = mixin BuddyDefinition!(5u, 16u, u32);

/**
 * Packer to randomly add voxels to and then compact into a input buffer.
 */
struct Packer
{
public:
	alias ArrType = Input2Cubed;
	enum u32 ArrNum = ArrType.ElementsNum;
	enum u32 ArrMask = ArrNum - 1;
	enum u32 ArrLevels = ArrType.Pow;


private:
	mLevels: u32;
	mArr: ArrType[];
	mArrNum: u32;


public:
	fn setup(levels: u32)
	{
		mLevels = levels;
		mArr = new ArrType[](256);
		mArrNum = 1;

		assert(mLevels % ArrLevels == 0);
	}

	fn add(x: u32, y: u32, z: u32, val: u32)
	{
		morton := cast(u32)(
			math.encode_component_3(x, XShift) |
			math.encode_component_3(y, YShift) |
			math.encode_component_3(z, ZShift));
		add(morton, val);
	}

	fn add(morton: u32, value: u32)
	{
		// First is always at zero.
		dst: u32 = 0;

		for (level := mLevels; level > ArrLevels; level -= ArrLevels) {

			shift := (level - 1) * NumDim;
			index := (morton >> shift) % ArrNum;

			if (mArr[dst].getBit(index)) {
				dst = mArr[dst].data[index];
				continue;
			}

			// Add a new Input and sett a pointer to it in the tree.
			newValue := newArr();
			mArr[dst].set(index, newValue);
			dst = newValue;
		}

		mArr[dst].set(morton % ArrNum, value);
	}

	fn toBuffer(ref ib: InputBuffer) u32
	{
		return decent(ref ib, 0, mLevels);
	}


private:
	fn decent(ref ib: InputBuffer, index: u32, level: u32) u32
	{
		// Final bottom level.
		if (level <= ArrLevels) {
			return ib.compressAndAdd(ref mArr[index]);
		}

		ptr := &mArr[index];

		// Translate indicies.
		foreach (i; 0u .. ArrNum) {
			if (!ptr.getBit(i)) {
				continue;
			}

			d := ptr.data[i];
			r := decent(ref ib, d, level - ArrLevels);
			ptr.set(i, r);
		}

		return ib.compressAndAdd(ref *ptr);
	}

	fn newArr() u32
	{
		if (mArrNum >= mArr.length) {
			old := mArr;
			mArr = new ArrType[](old.length + 256);
			mArr[0 .. old.length] = old[..];
		}
		return mArrNum++;
	}
}

/**
 * Helper struct that holds common code to compress InputXCubed data.
 */
struct CompressingBuffer!(Base)
{
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

	/**
	 * Adds a Input and does a very simple compression suited
	 * for rendering on the GPU.
	 */
	fn compressAndAdd(ref box: Input2Cubed) u32
	{
		buf: u32[Input2Cubed.ElementsNum + 1];
		count: u32;

		buf[count++] = (1u << 16u) | box.u.flags[0];

		foreach (i; 0 .. Input2Cubed.ElementsNum) {
			if (box.getBit(i)) {
				buf[count++] = box.data[i];
			}
		}

		return base.add(buf[0 .. count]);
	}

	/**
	 * Adds a Input and does a very simple compression suited
	 * for rendering on the GPU.
	 */
	fn compressAndAdd(ref box: Input4Cubed) u32
	{
		// Reserve the start of the packed values for flags.
		num := 4u;
		packed: u32[4 + 64];

		foreach (i; 0u .. 64u) {

			flagIndex := i / 16u;

			// Write the offset for the values here.
			if (i % 16 == 0) {
				packed[flagIndex] |= num << 16u;
			}

			if (!box.getBit(i)) {
				continue;
			}

			// Add the value to the packed struct.
			packed[num++] = box.data[i];
		}

		return base.add(packed[0 .. num]);
	}
}

/// Linear buffer for filling up voxel data.
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

	/**
	 * Returns the entire data buffer as void array.
	 */
	fn getData() void[]
	{
		return cast(void[])(mData[0 .. mNumData]);
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

/**
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

	/**
	 * Returns the entire data buffer as void array.
	 */
	fn getData() void[]
	{
		return cast(void[])mData[0 .. mMaxSize];
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
