// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for morton encoding code.
 */
module charge.math.morton;


fn encode(x: u32, y: u32) u64
{
	return encode_component_2(x, 0) |
	       encode_component_2(y, 1);
}

fn encode(x: u32, y: u32, z: u32) u64
{
	return encode_component_3(x, 0) |
	       encode_component_3(y, 1) |
	       encode_component_3(z, 2);
}

fn decode2(p: u64, out result: u32[2])
{
	result[0] = decode_component_2(p, 0);
	result[1] = decode_component_2(p, 1);
}

fn decode3(p: u64, out result: u32[3])
{
	result[0] = decode_component_3(p, 0);
	result[1] = decode_component_3(p, 1);
	result[2] = decode_component_3(p, 2);
}

fn encode_component_2(x: u64, shift: u64) u64
{
// x = ---- ---- ---- ----  ---- ---- ---- ----  fedc ba98 7654 3210  fedc ba98 7654 3210
// x = ---- ---- ---- ----  fedc ba98 7654 3210  ---- ---- ---- ----  fedc ba98 7654 3210
// x = ---- ---- fedc ba98  ---- ---- 7654 3210  ---- ---- fedc ba98  ---- ---- 7654 3210
// x = ---- fedc ---- ba98  ---- 7654 ---- 3210  fedc ---- ba98 ----  ---- 7654 ---- 3210
// x = --ef --dc --ba --98  --76 --54 --32 --10  --ef --dc --ba --98  --76 --54 --32 --10
// x = -f-e -d-c -b-a -9-8  -7-6 -5-4 -3-2 -1-0  -f-e -d-c -b-a -9-8  -7-6 -5-4 -3-2 -1-0
	x =             x & 0x0000_0000_ffff_ffffUL;
	x = (x | x << 16) & 0x0000_ffff_0000_ffffUL;
	x = (x | x << 8)  & 0x00ff_00ff_00ff_00ffUL;
	x = (x | x << 4)  & 0x0f0f_0f0f_0f0f_0f0fUL;
	x = (x | x << 2)  & 0x3333_3333_3333_3333UL;
	x = (x | x << 1)  & 0x5555_5555_5555_5555UL;
	return x << shift;
}

fn encode_component_3(x: u64, shift: u64) u64
{
// x = ---- ---- ---- ----  ---- ---- ---- ----  ---- ---- ---4 3210  fedc ba98 7654 3210
// x = ---- ---- ---4 3210  ---- ---- ---- ----  ---- ---- ---- ----  fedc ba98 7654 3210
// x = ---- ---- ---4 3210  ---- ---- ---- ----  fedc ba98 ---- ----  ---- ---- 7654 3210
// x = ---4 ---- ---- 3210  ---- ---- fedc ----  ---- ba98 ---- ----  7654 ---- ---- 3210
// x = ---4 ---- 32-- --10  ---- fe-- --dc ----  ba-- --98 ---- 76--  --54 ---- 32-- --10
// x = ---4 --3- -2-- 1--0  --f- -e-- d--c --b-  -a-- 9--8 --7- -6--  5--4 --3- -2-- 1--0
	x =             x & 0x0000_0000_001f_ffffUL;
	x = (x | x << 32) & 0x001f_0000_0000_ffffUL;
	x = (x | x << 16) & 0x001f_0000_ff00_00ffUL;
	x = (x | x << 8)  & 0x100f_00f0_0f00_f00fUL;
	x = (x | x << 4)  & 0x10c3_0c30_c30c_30c3UL;
	x = (x | x << 2)  & 0x1249_2492_4924_9249UL;
	return x << shift;
}

fn decode_component_2(x: u64, shift: u64) u32
{
// x = ---- ---- ---- ----  ---- ---- ---- ----  fedc ba98 7654 3210  fedc ba98 7654 3210
// x = ---- ---- ---- ----  fedc ba98 7654 3210  ---- ---- ---- ----  fedc ba98 7654 3210
// x = ---- ---- fedc ba98  ---- ---- 7654 3210  ---- ---- fedc ba98  ---- ---- 7654 3210
// x = ---- fedc ---- ba98  ---- 7654 ---- 3210  fedc ---- ba98 ----  ---- 7654 ---- 3210
// x = --ef --dc --ba --98  --76 --54 --32 --10  --ef --dc --ba --98  --76 --54 --32 --10
// x = -f-e -d-c -b-a -9-8  -7-6 -5-4 -3-2 -1-0  -f-e -d-c -b-a -9-8  -7-6 -5-4 -3-2 -1-0
	x =   (x >> shift)  & 0x5555_5555_5555_5555UL;
	x = (x ^ (x >> 1))  & 0x3333_3333_3333_3333UL;
	x = (x ^ (x >> 2))  & 0x0f0f_0f0f_0f0f_0f0fUL;
	x = (x ^ (x >> 4))  & 0x00ff_00ff_00ff_00ffUL;
	x = (x ^ (x >> 8))  & 0x0000_ffff_0000_ffffUL;
	x = (x ^ (x >> 16)) & 0x0000_0000_ffff_ffffUL;
	return cast(u32)x;
}

fn decode_component_3(x: u64, shift: u64) u32
{
// x = ---4 --3- -2-- 1--0  --f- -e-- d--c --b-  -a-- 9--8 --7- -6--  5--4 --3- -2-- 1--0
// x = ---4 ---- 32-- --10  ---- fe-- --dc ----  ba-- --98 ---- 76--  --54 ---- 32-- --10
// x = ---4 ---- ---- 3210  ---- ---- fedc ----  ---- ba98 ---- ----  7654 ---- ---- 3210
// x = ---- ---- ---4 3210  ---- ---- ---- ----  fedc ba98 ---- ----  ---- ---- 7654 3210
// x = ---- ---- ---4 3210  ---- ---- ---- ----  ---- ---- ---- ----  fedc ba98 7654 3210
// x = ---- ---- ---- ----  ---- ---- ---- ----  ---- ---- ---4 3210  fedc ba98 7654 3210
	x =   (x >> shift)  & 0x1249_2492_4924_9249UL;
	x = (x ^ (x >> 2))  & 0x10c3_0c30_c30c_30c3UL;
	x = (x ^ (x >> 4))  & 0x100f_00f0_0f00_f00fUL;
	x = (x ^ (x >> 8))  & 0x001f_0000_ff00_00ffUL;
	x = (x ^ (x >> 16)) & 0x001f_0000_0000_ffffUL;
	x = (x ^ (x >> 32)) & 0x0000_0000_001f_ffffUL;
	return cast(u32)x;
}
