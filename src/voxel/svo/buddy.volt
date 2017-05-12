// Copyright © 2016-2017, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * A simple buddy allocator, only does tracking of which blocks are free
 */
module voxel.svo.buddy;


fn isPowerOfTwo(n: size_t) bool
{
	return (n != 0) && ((n & (n - 1)) == 0);
}

fn nextHighestPowerOfTwo(n: size_t) size_t
{
	if (isPowerOfTwo(n)) {
		return n;
	}
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	return ++n;
}

fn sizeToOrder(n: size_t) u8
{
	pot := cast(u32)nextHighestPowerOfTwo(n);
	return cast(u8)countTrailingZeros(pot, true);
}

fn orderToSize(order: u8) size_t
{
	return 1U << order;
}


/**
 * Buddy allocator template with adjustable size and internal element
 * representation.
 */
struct BuddyDefinition!(MIN: size_t, MAX: size_t, T)
{
public:
	enum MinOrder = MIN;
	enum MaxOrder = MAX;
	enum LargestOrder = NumLevels - 1;
	enum NumLevels = MaxOrder - MinOrder + 1;


private:
	alias ElmType = T;
	enum NumBitsPerElm = typeid(ElmType).size * 8u;
	enum NumBits = (1u << (MaxOrder+1)) - (1 << MinOrder);
	enum NumElems = NumBits / NumBitsPerElm;

	mNumFree: size_t[NumLevels];
	mLowestFreeIndex: size_t[NumLevels];
	mBitmap: ElmType[NumElems];


public:
	fn setup()
	{
		// For "buddy := index ^ 1;"
		assert(NumLevels > 0);
		// Just to be safe.
		assert(NumBitsPerElm == (1 << MinOrder));

		// Mark the first order and first index as free.
		mBitmap[0] = cast(ElmType)-1;
		mNumFree[LargestOrder] = numBitsInOrder(LargestOrder);
		mLowestFreeIndex[LargestOrder] = offsetOfOrder(LargestOrder);
	}

	// Reserve n max order blocks from the beginning of memory.
	fn reserveStart(n: size_t)
	{
		foreach (i; 0 .. n) {
			assert(canAlloc(0));
			ret := alloc(0);
			assert(ret == i);
		}
	}

	// Returns true if the buddy allocator can allocate from this order.
	fn canAlloc(order: size_t) bool
	{
		if (order > LargestOrder) {
			return false;
		}
		if (mNumFree[order] > 0) {
			return true;
		}
		return canAlloc(order + 1);
	}

	// One block from the given order, may split orders above to make room.
	// It does no error checking so make sure you can alloc from a given
	// order with canAlloc before calling this function.
	fn alloc(order: size_t) size_t
	{
		if (mNumFree[order] > 0) {
			return takeFree(order);
		}

		base := alloc(order + 1) * 2;
		free(order, base + 1);
		return base;
	}

	// Free one block of the given order and index. Will merge any buddies.
	// As with all of the other functions don't call if you are certain
	// you can free the block that is given to this function.
	fn free(order: size_t, n: size_t)
	{
		index := indexOf(order, n);
		buddy := index ^ 1;

		// Either the top order or the buddy is not set.
		if (order == LargestOrder || !getBit(buddy)) {
			addFree(order);
			setBit(index);
			if (mLowestFreeIndex[order] > index || mNumFree[order] == 1) {
				mLowestFreeIndex[order] = index;
			}
			return;
		}

		// Buddy is also set: allocate it, merge it and
		// propagate up to the next order.
		clearBit(buddy);
		subFree(order);
		free(order + 1, n >> 1);
	}


private:
	fn addFree(order: size_t)
	{
		mNumFree[order]++;
	}

	fn subFree(order: size_t)
	{
		mNumFree[order]--;
	}

	fn getBit(index: size_t) bool
	{
		elmIndex := index / NumBitsPerElm;
		bitIndex := index % NumBitsPerElm;

		return cast(bool)(mBitmap[elmIndex] >> bitIndex & 1);
	}

	fn setBit(index: size_t)
	{
		elmIndex := index / NumBitsPerElm;
		bitIndex := index % NumBitsPerElm;

		mBitmap[elmIndex] |= cast(ElmType)(1 << bitIndex);
	}

	fn clearBit(index: size_t)
	{
		elmIndex := index / NumBitsPerElm;
		bitIndex := index % NumBitsPerElm;

		// Use xor so we don't need to invert bits.
		// If the bit is not set this will cause a error.
		mBitmap[elmIndex] ^= cast(ElmType)(1 << (bitIndex));
	}

	fn takeFree(order: size_t) size_t
	{
		startbit := offsetOfOrder(order);
		i := mLowestFreeIndex[order];
		if (getBit(i)) {
			clearBit(i);
			subFree(order);
			mLowestFreeIndex[order] = i ^ 1;
			return i - startbit;
		}
		start := startbit / NumBitsPerElm;
		endbit := startbit + numBitsInOrder(order);
		end := endbit / NumBitsPerElm;

		foreach (ei, ref elm; mBitmap[start .. end]) {
			if (elm == 0) {
				continue;
			}
			i = countTrailingZeros(elm, true) + startbit + ei * NumBitsPerElm;
			clearBit(i);
			subFree(order);
			return i - startbit;
		}
		assert(false);
	}

	static fn indexOf(order: size_t, n: size_t) size_t
	{
		return offsetOfOrder(order) + n;
	}

	static fn offsetOfOrder(order: size_t) size_t
	{
		order = MaxOrder - order;
		return (1 << order) - (1 << MinOrder);
	}

	static fn numBitsInOrder(order: size_t) size_t
	{
		order = MaxOrder - order;
		return 1 << order;
	}
}

@mangledName("llvm.cttz.i8")
fn countTrailingZeros(bits: u8, isZeroUndef: bool) u8;
@mangledName("llvm.cttz.i16")
fn countTrailingZeros(bits: u16, isZeroUndef: bool) u16;
@mangledName("llvm.cttz.i32")
fn countTrailingZeros(bits: u32, isZeroUndef: bool) u32;
@mangledName("llvm.cttz.i64")
fn countTrailingZeros(bits: u64, isZeroUndef: bool) u64;
