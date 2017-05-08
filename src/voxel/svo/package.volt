// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo;

import charge.core;
import io = watt.io;


fn test()
{
	t: Input1;

	io.output.writefln("Pow          %s", Input1.Pow);
	io.output.writefln("Size         %s", Input1.Size);
	io.output.writefln("NumElements  %s", Input1.NumElements);
	io.output.writefln("XStride      %s", Input1.XStride);
	io.output.writefln("YStride      %s", Input1.YStride);
	io.output.writefln("ZStride      %s", Input1.ZStride);
	io.output.writefln("FlagsNumBits %s", Input1.FlagsNumBits);
	io.output.writefln("");
	io.output.writefln("Pow          %s", Input2.Pow);
	io.output.writefln("Size         %s", Input2.Size);
	io.output.writefln("NumElements  %s", Input2.NumElements);
	io.output.writefln("XStride      %s", Input2.XStride);
	io.output.writefln("YStride      %s", Input2.YStride);
	io.output.writefln("ZStride      %s", Input2.ZStride);
	io.output.writefln("FlagsNumBits %s", Input2.FlagsNumBits);
	io.output.writefln("");
	io.output.writefln("Pow          %s", Input3.Pow);
	io.output.writefln("Size         %s", Input3.Size);
	io.output.writefln("NumElements  %s", Input3.NumElements);
	io.output.writefln("XStride      %s", Input3.XStride);
	io.output.writefln("YStride      %s", Input3.YStride);
	io.output.writefln("ZStride      %s", Input3.ZStride);
	io.output.writefln("FlagsNumBits %s", Input3.FlagsNumBits);
	io.output.flush();
}

enum NumDim = 3;
enum XShift = 0;
enum YShift = 1;
enum ZShift = 2;

struct InputTemplate!(MAX: u32)
{
	enum Pow = MAX;
	enum Size = 1 << Pow;
	enum NumElements = 1 << (Pow * NumDim);
	enum XStride = 1 << (Pow * XShift);
	enum YStride = 1 << (Pow * YShift);
	enum ZStride = 1 << (Pow * ZShift);
	enum FlagsNumBits = 8u;

	data: uint[NumElements];
	flags: u8[NumElements / FlagsNumBits];

	fn set(x: uint, y: uint, z: uint, d: uint)
	{
		x %= Size; y %= Size; z %= Size;

		index := x * XStride + y * YStride + z * ZStride;
		data[index] = d;
		flags[index / FlagsNumBits] |= cast(u8)(1 << (index % FlagsNumBits));
	}
}

struct Input1 = mixin InputTemplate!(1);
struct Input2 = mixin InputTemplate!(2);
struct Input3 = mixin InputTemplate!(3);
