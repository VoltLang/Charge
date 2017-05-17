// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.util;


struct BufferTracker
{
	bits: u32;
	numFree: u32;

	fn setup(num: u32)
	{
		numFree = num;
		foreach (i; 0 .. num) {
			bits |= (1 << i);
		}
	}

	fn get() u32
	{
		assert(numFree > 0);
		index := countTrailingZeros(bits, true);
		bits = bits ^ (1 << index);
		return index;
	}

	fn free(index: u32)
	{
		numFree++;
		bits |= 1 << index;
	}
}

@mangledName("llvm.cttz.i32")
fn countTrailingZeros(bits: u32, isZeroUndef: bool) u32;
