// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Contains the @ref FlatGen svo generator.
 */
module voxel.generators.flat;

import voxel.svo.design;
import voxel.svo.input;
import voxel.svo.packer;


/*!
 * Generates a flat surface on the Y plane.
 */
struct FlatGen
{
public:
	enum Max = 32;
	enum ColorLevels = 7;


private:
	mArr: Input2Cubed[64*64+32*32+16*16+8*8+4*4+2*2+1];
	mPos: u32;


public:
	/*!
	 * Generate a completely flat white surface.
	 */
	fn genYWhite(ref ib: InputBuffer, levels: u32) u32
	{
		assert(levels < mArr.length);

		// Initial bits.
		mArr[levels-1].set(0, 1, 0, 0xff_ff_ff_ff);
		mArr[levels-1].set(1, 1, 0, 0xff_ff_ff_ff);
		mArr[levels-1].set(1, 1, 1, 0xff_ff_ff_ff);
		mArr[levels-1].set(0, 1, 1, 0xff_ff_ff_ff);

		foreach (i; 1 .. levels) {
			targetPos := levels - i;
			arrPos := levels - i - 1;

			mArr[arrPos].set(0, 0, 0, targetPos);
			mArr[arrPos].set(1, 0, 0, targetPos);
			mArr[arrPos].set(1, 0, 1, targetPos);
			mArr[arrPos].set(0, 0, 1, targetPos);
		}

		packer: Packer;
		packer.setup(levels, mArr[0 .. levels]);
		return packer.toBuffer(ref ib);
	}

	/*!
	 * Generate a completely flat colored surface.
	 */
	fn genYColored(ref ib: InputBuffer, levels: u32) u32
	{
		mPos = 0;
		ret := paint(0, 0, ColorLevels);
		assert(ret == 0);

		packer: Packer;
		packer.setup(ColorLevels, mArr[0 .. mPos]);
		return packer.toBuffer(ref ib, levels, true);
	}


private:
	fn paint(x: u32, z: u32, level: u32) u32
	{
		x = x << 1;
		z = z << 1;

		level--;
		pos := mPos++;
		elm := &mArr[pos];

		if (level == 0) {
			elm.set(0, 1, 0, getColor(x + 0, z + 0));
			elm.set(1, 1, 0, getColor(x + 1, z + 0));
			elm.set(1, 1, 1, getColor(x + 1, z + 1));
			elm.set(0, 1, 1, getColor(x + 0, z + 1));
		} else {
			elm.set(0, 0, 0, paint(x + 0, z + 0, level));
			elm.set(1, 0, 0, paint(x + 1, z + 0, level));
			elm.set(1, 0, 1, paint(x + 1, z + 1, level));
			elm.set(0, 0, 1, paint(x + 0, z + 1, level));
		}

		return pos;
	}

	global fn getColor(x: u32, z: u32) u32
	{
		xf := cast(f32)x / (1 << ColorLevels) * 255.f;
		zf := cast(f32)z / (1 << ColorLevels) * 255.f;
		return 0xff_00_00_00 + (cast(u8)xf << 16u) + (cast(u8)zf << 0u);
	}
}
