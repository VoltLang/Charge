// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Contains variours small svo generators.
 */
module voxel.svo.gen;

import voxel.svo.design;
import voxel.svo.input;


/*
 * Generates a single voxel at origin (0, 0, 0).
 */
struct OneGen
{
public:
	enum Max = 32;

private:
	t: Input2Cubed;
	pos: u32[Max];


public:
	/**
	 * Generate a completely flat white surface.
	 */
	fn gen(ref ib: InputBuffer, levels: u32) u32
	{
		assert(levels < Max);

		count: u32;

		// Initial bits.
		t.set(0, 0, 0, 0xff_ff_ff_ff);
		pos[count] = ib.compressAndAdd(ref t);
		t.reset();

		foreach (i; 1 .. levels) {
			targetPos := pos[count++];

			t.set(0, 0, 0, targetPos);
			pos[count] = ib.compressAndAdd(ref t);
			t.reset();
		}

		return pos[count];
	}
}

struct FlatGen
{
public:
	enum Max = 32;

private:
	t: Input2Cubed;
	pos: u32[Max];


public:
	/**
	 * Generate a completely flat white surface.
	 */
	fn genY(ref ib: InputBuffer, levels: u32) u32
	{
		assert(levels < Max);

		count: u32;

		// Initial bits.
		t.set(0, 1, 0, 0xff_ff_ff_ff);
		t.set(1, 1, 0, 0xff_ff_ff_ff);
		t.set(1, 1, 1, 0xff_ff_ff_ff);
		t.set(0, 1, 1, 0xff_ff_ff_ff);
		pos[count] = ib.compressAndAdd(ref t);
		t.reset();

		foreach (i; 1 .. levels) {
			targetPos := pos[count++];

			t.set(0, 0, 0, targetPos);
			t.set(1, 0, 0, targetPos);
			t.set(1, 0, 1, targetPos);
			t.set(0, 0, 1, targetPos);
			pos[count] = ib.compressAndAdd(ref t);
			t.reset();
		}

		return pos[count];
	}
}
