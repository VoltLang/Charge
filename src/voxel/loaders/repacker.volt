// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Code for packing voxels into a oct-tree.
 */
module voxel.loaders.repacker;

import io = watt.io;

import math = charge.math;

import voxel.svo.buddy : sizeToOrder;
import voxel.svo.design;
import voxel.svo.input;


fn repackFrom(ref dst: Input4Cubed, arr: scope Input2Cubed[], start: u32)
{
	top := &arr[start];

	foreach (i; 0u .. 8u) {
		if (!top.getBit(i)) {
			continue;
		}

		bottom := &arr[top.data[i]];
		foreach (j; 0u .. 8u) {
			if (!bottom.getBit(j)) {
				continue;
			}

			morton := (i << 3) + j;
			dst.set(morton, bottom.data[j]);
		}
	}
}

fn repackFrom(ref dst: Input8Cubed, arr: scope Input2Cubed[], start: u32)
{
	top := &arr[start];

	foreach (i; 0u .. 8u) {
		if (!top.getBit(i)) {
			continue;
		}

		middle := &arr[top.data[i]];
		foreach (j; 0u .. 8u) {
			if (!middle.getBit(j)) {
				continue;
			}

			bottom := &arr[middle.data[j]];
			foreach (k; 0u .. 8u) {
				if (!bottom.getBit(k)) {
					continue;
				}

				morton := (i << 6) + (j << 3) + k;
				dst.set(morton, bottom.data[k]);
			}
		}
	}
}

struct MyPacker = mixin Packer!(8, Input2Cubed, Input4Cubed);

/**
 * WIP custamizable packer.
 */
struct Packer!(totalLevels: u32, TOP, BOTTOM)
{
public:
	alias NumLevels = totalLevels;
	alias TopType = Input2Cubed; // TODO workaround bug
	alias BottomType = Input4Cubed; // TODO workaround bug.

	enum u32 TopNum = TopType.ElementsNum;
	enum u32 TopMask = TopNum - 1;
	enum u32 TopLevels = TopType.Pow;

	enum u32 BottomNum = BottomType.ElementsNum;
	enum u32 BottomMask = BottomNum - 1;
	enum u32 BottomLevels = BottomType.Pow;

	static assert ((NumLevels - BottomLevels) % TopLevels == 0);
	static assert (is(TopType == TOP));
	static assert (is(BottomType == BOTTOM));


private:
	mTop: TopType[];
	mTopNum: u32;
	mBottom: BottomType[];
	mBottomNum: u32;


public:
	fn setup()
	{

		mTop = new TopType[](256);
		mBottom = new BottomType[](32);
		mTopNum = 1;
		mBottomNum = 0;
	}

	fn add(morton: u32, value: u32)
	{
		// First is always at zero.
		dst: u32 = 0;

		// 1000 -> 0001 3
		// 0100 -> 0001 2
		// 0010 -> 0001 1
		// 0001 -> 0001 0

		for (level := NumLevels - BottomType.Pow; level > 0; level -= TopType.Pow) {
			shift := level * NumDim;
			index := (morton >> shift) % TopMask;

			if (mTop[dst].getBit(index)) {
				dst = mTop[dst].data[index];
				continue;
			}

			// Add a new Input and sett a pointer to it in the tree.
			newIndex: u32;
			if (level == BottomType.Pow) {
				newIndex = newTop();
			} else {
				newIndex = newBottom();
			}

			mTop[dst].set(index, newIndex);
			dst = newIndex;
		}

		mTop[dst].set(morton & BottomMask, value);
	}


private:
	fn decent(ref ib: InputBuffer, index: u32, level: u32) u32
	{
		// Final bottom level.
		if (level <= BottomType.Pow) {
			return ib.compressAndAdd(ref mBottom[index]);
		}

		ptr := &mTop[index];

		// Translate indicies.
		foreach (i; 0u .. 8u) {
			if (!ptr.getBit(i)) {
				continue;
			}

			d := ptr.data[i];
			r := decent(ref ib, d, level - 1);
			ptr.set(i, r);
		}

		return ib.compressAndAdd(ref *ptr);
	}

	fn newTop() u32
	{
		if (mTopNum >= mTop.length) {
			old := mTop;
			mTop = new TopType[](old.length + 256);
			mTop[0 .. old.length] = old[];
		}
		return mTopNum++;
	}

	fn newBottom() u32
	{
		if (mBottomNum >= mBottom.length) {
			old := mBottom;
			mBottom = new BottomType[](old.length + 256);
			mBottom[0 .. old.length] = old[];
		}
		return mBottomNum++;
	}
}
