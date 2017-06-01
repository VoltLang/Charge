// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.util;

import watt.math.floating;


/*!
 * A helper struct to get the distance that a
 * Voxel of a given level is one pixel large.
 */
struct VoxelDistanceFinder
{
public:
	enum f64 SQRT2 = 1.414213562373095;

	ratio: f64;
	halfPixels: f64;
	tanHalfFov: f64;


public:
	fn setup(fov: f64, width: u32, height: u32)
	{
		ratio = cast(f64)width / cast(f64)height;
		tanHalfFov = tan(fov / 2.0);
		halfPixels = width / 2.0;
	}

	fn getDistance(level: i32) f64
	{
		// Voxel size in one dimension.
		voxelSize := 1.0 / cast(f64)(1 << level);

		// Distance between two oposing corners of the voxel.
		voxelSizeAdjusted := voxelSize * SQRT2 + voxelSize / 32.0;

		return (halfPixels * voxelSizeAdjusted) / (tanHalfFov * ratio);
	}
}

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
