// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for morton encoding code.
 */
module charge.math.morton;


u64 encode(u32 x, u32 y)
{
	return encode_component_2(x, 0) |
	       encode_component_2(y, 1);
}

u64 encode(u32 x, u32 y, u32 z)
{
	return encode_component_3(x, 0) |
	       encode_component_3(y, 1) |
	       encode_component_3(z, 2);
}

void decode2(u64 p, out u32[2] result)
{
	result[0] = decode_component_2(p, 0);
	result[1] = decode_component_2(p, 1);
}

void decode3(u64 p, out u32[3] result)
{
	result[0] = decode_component_3(p, 0);
	result[1] = decode_component_3(p, 1);
	result[2] = decode_component_3(p, 2);
}

u64 encode_component_2(u64 x, u64 shift)
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

u64 encode_component_3(u64 x, u64 shift)
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

u32 decode_component_2(u64 x, u64 shift)
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

u32 decode_component_3(u64 x, u64 shift)
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
