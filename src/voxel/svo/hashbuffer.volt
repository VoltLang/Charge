// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * A specialiced hashmap and buffer.
 */
module voxel.svo.hashbuffer;

import io = watt.io;

import core.compiler.llvm : __llvm_memset;
import core.rt.misc : vrt_hash;

import watt.math;
import watt.algorithm;

import sys = charge.sys;

import voxel.svo.buddy : nextHighestPowerOfTwo;


/*!
 * A hash map and buffer.
 */
struct HashBuffer
{
private:
	mBuf: ReallocU32Ptr;
	mHash: ReallocU64Ptr;
	mTries: u32;
	mCounter: u32;
	mEntries: u32;
	mHashEntriesMinesOne: u32;

	enum BufChunk = 1024*1024;
	alias EntryType = u64;


public:
	@property fn ptr() u32*
	{
		return mBuf.ptr;
	}

	@property fn length() size_t
	{
		return mCounter;
	}

	fn setup(numReserved: u32)
	{
		// Really big for now.
		this.setup(16u*1024u*1024u, 1u << 22u, numReserved);
	}

	fn setup(startBufferSize: u32, startHashSize: u32, numReserved: u32)
	{
		ensureBufSpace(max(startBufferSize, numReserved));
		growHash(max(startHashSize, 128) - 1);
		mCounter = numReserved;
	}

	fn close()
	{
		mBuf.free();
		mHash.free();
		mCounter = 0;
		mEntries = 0;
		mTries = 0;
		mHashEntriesMinesOne = 0;
	}

	fn takeMemory(out count: u32) u32[]
	{
		count = mCounter;
		length := mBuf.num;
		ptr := mBuf.takePtrAndClear();
		close();
		return ptr[0 .. length];
	}

	fn add(data: scope const(u32)[]) u32
	{
		t1 := data.length > 0;
		t2 := data.length + mCounter < u32.max;
		t3 := data.length < u32.max;

		// This hack allows is to assert even on release builds.
		if (t1 & t2 & t3) {
			return addChecked(data);
		}

		assert(false);
	}


private:
	fn addChecked(data: scope const(u32)[]) u32
	{
		hash := makeHash(data);
		index := getHashIndex(hash);

		for (i := 0u; i < mTries; i++, index++) {
			entry := getEntry(index);
			if (entry == 0) {
				continue;
			}

			eIndex := getEntryIndex(entry);
			eLength := getEntryLength(entry);

			val := mBuf.ptr[eIndex .. eIndex + eLength];
			if (val == data) {
				return eIndex;
			}
		}

		return emplaceChecked(data, hash);
	}

	fn emplaceChecked(data: scope const(u32)[], hash: u64) u32
	{
		ensureBufSpace(data.length);

		hashIndex := getHashIndex(hash);
		bufIndex := mCounter;
		len := cast(u32)data.length;


		for (i := 0u; i < mTries; i++, hashIndex++) {
			entry := getEntry(hashIndex);
			if (entry != 0) {
				continue;
			}

			mCounter += len;
			mEntries++;

			setEntry(hashIndex, bufIndex, len);
			mBuf.ptr[bufIndex .. bufIndex + len] = data[..];
			return bufIndex;
		}

		io.writefln("Due to programmer lazyness this specialiced hashmap can not grow.");
		io.writefln("Dubug mTries: %s, mEntries: %s", mTries, mEntries);
		io.output.flush();
		assert(false);
	}

	fn setEntry(hashIndex: u32, bufIndex: u32, length: u32)
	{
		mHash.ptr[hashIndex] = bufIndex | (cast(EntryType)length << 32u);
	}

	fn getEntry(hashIndex: u32) EntryType
	{
		return mHash.ptr[hashIndex];
	}

	global fn getEntryIndex(entry: EntryType) u32
	{
		return cast(u32)(entry & 0xff_ff_ff_ff);
	}

	global fn getEntryLength(entry: EntryType) size_t
	{
		return cast(size_t)(entry >> 32u);
	}

	global fn makeHash(data: scope const(u32)[]) u64
	{
		return hashFNV1A(data);
	}

	fn getHashIndex(hash: u64) u32
	{
		return cast(u32)(hash & mHashEntriesMinesOne);
	}

	fn ensureBufSpace(extra: size_t)
	{
		if (mBuf.fits(mCounter + extra)) {
			return;
		}

		// Grow the buffer in increments of BufChunk.
		newSize := mBuf.num;
		while (newSize < mCounter + extra) {
			newSize += BufChunk;
		}

		mBuf.resize(newSize);
	}

	fn growHash(min: size_t)
	{
		tmp := max(min, mHash.num);
		assert(tmp < u32.max);

		num := cast(u32)nextHighestPowerOfTwo(tmp);
		mTries = log2(num);
		mHash.resize(num + mTries + 1);
		mHashEntriesMinesOne = num - 1;
	}
}

/*!
 * Helper growing pointer.
 */
struct ReallocPtr!(T)
{
public:
	ptr: T*;
	num: size_t;


public:
	fn takePtrAndClear() T*
	{
		ret := ptr;
		ptr = null;
		num = 0;
		return ret;
	}

	fn fits(min: size_t) bool
	{
		return min <= num;
	}

	fn resize(newNum: size_t)
	{
		oldSize := num * typeid(T).size;
		newSize := newNum * typeid(T).size;
		newPtr := sys.cRealloc(cast(void*)ptr, newSize);

		__llvm_memset(newPtr + oldSize, 0, newSize - oldSize, 4, false);
		ptr = cast(T*)newPtr;
		num = newNum;
	}

	fn free()
	{
		if (ptr is null) {
			return;
		}

		sys.cFree(cast(void*)takePtrAndClear());
	}
}

struct ReallocU32Ptr = mixin ReallocPtr!(u32);
struct ReallocU64Ptr = mixin ReallocPtr!(u64);

/*!
 * Produces slightly fewer hash collisions then crc32.
 */
fn hashFNV1A(key: scope const(u32)[]) u64
{
	p := cast(u8*)key.ptr;
	l := key.length * 4;
	h := 0xcbf29ce484222325_u64;

	foreach (v; p[0 .. l]) {
		h = (h ^ v) * 0x100000001b3_u64;
	}

	return h;
}
