// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Code for packing voxels into a oct-tree.
 */
module voxel.svo.packer;

import math = charge.math;

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

/*!
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

	/*!
	 * Compresses the SVO into the given InputBuffer, allows you to add
	 * extra levels.
	 */
	fn toBuffer(ref ib: InputBuffer, totalLevels: u32, repeat: bool) u32
	{
		ret := toBuffer(ref ib);

		foreach (i; 0 .. totalLevels - mLevels) {
			tmp: Input2Cubed;
			tmp.set(0, 0, 0, ret);
			if (repeat) {
				tmp.set(0, 0, 1, ret);
				tmp.set(1, 0, 1, ret);
				tmp.set(1, 0, 0, ret);
			}
			ret = ib.compressAndAdd(ref tmp);
		}

		return ret;
	}

	/*!
	 * Compresses the SVO into the given InputBuffer.
	 */
	fn toBuffer(ref ib: InputBuffer) u32
	{
		return decent(ref ib, 0, mLevels);
	}


private:
	fn decent(ref ib: InputBuffer, index: u32, level: u32) u32
	{
		// Final bottom level.
		if (level <= Input4Cubed.Pow) {
			return finalLevels(ref ib, index);
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

	fn finalLevels(ref ib: InputBuffer, index: u32) u32
	{
		large: Input4Cubed;
		large.repackFrom(mArr, index);

		ptr := &mArr[index];

		// Translate indicies.
		foreach (i; 0u .. ArrNum) {
			if (!ptr.getBit(i)) {
				continue;
			}

			d := ptr.data[i];
			r := ib.compressAndAdd(ref mArr[d]);
			ptr.set(i, r);
		}

		return ib.compressAndAdd(ref *ptr, ref large);
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

//! Example custom packer.
struct MyPacker = mixin CustomPacker!(8, Input2Cubed, Input4Cubed);

/*!
 * Custamizable packer.
 */
struct CustomPacker!(totalLevels: u32, TOP, BOTTOM)
{
public:
	alias NumLevels = totalLevels;
	alias TopType = TOP;
	alias BottomType = BOTTOM;

	enum u32 TopNum = TopType.ElementsNum;
	enum u32 TopMask = TopNum - 1;
	enum u32 TopLevels = TopType.Pow;

	enum u32 BottomNum = BottomType.ElementsNum;
	enum u32 BottomMask = BottomNum - 1;
	enum u32 BottomLevels = BottomType.Pow;

	
	static assert (is(TopType == TOP));
	static assert (is(BottomType == BOTTOM));


private:
	mLevels: u32;
	mTop: TopType[];
	mTopNum: u32;
	mBottom: BottomType[];
	mBottomNum: u32;


public:
	fn setup(levels: u32)
	{
		mLevels = levels;
		mTop = new TopType[](256);
		mBottom = new BottomType[](32);
		mTopNum = 1;
		mBottomNum = 0;

		assert((mLevels - BottomLevels) % TopLevels == 0);
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

		for (level := mLevels; level > BottomType.Pow; level -= TopLevels) {

			shift := (level - 1) * NumDim;
			index := (morton >> shift) % TopNum;

			if (mTop[dst].getBit(index)) {
				dst = mTop[dst].data[index];
				continue;
			}

			// Add a new Input and sett a pointer to it in the tree.
			newValue: u32;
			if ((level - TopType.Pow) > BottomType.Pow) {
				newValue = newTop();
			} else {
				newValue = newBottom();
			}

			mTop[dst].set(index, newValue);
			dst = newValue;
		}

		mBottom[dst].set(morton % BottomNum, value);
	}

	fn toBuffer(ref ib: InputBuffer) u32
	{
		return decent(ref ib, 0, mLevels);
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
		foreach (i; 0u .. TopNum) {
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
			mTop[0 .. old.length] = old[..];
		}
		return mTopNum++;
	}

	fn newBottom() u32
	{
		if (mBottomNum >= mBottom.length) {
			old := mBottom;
			mBottom = new BottomType[](old.length + 256);
			mBottom[0 .. old.length] = old[..];
		}
		return mBottomNum++;
	}
}
