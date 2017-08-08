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


private:
	t: Input2Cubed;
	mArr: Input2Cubed[Max];


public:
	/*!
	 * Generate a completely flat white surface.
	 */
	fn genY(ref ib: InputBuffer, levels: u32) u32
	{
		assert(levels < Max);

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
		packer.setup(11, mArr[0 .. levels]);
		return packer.toBuffer(ref ib);
	}
}
