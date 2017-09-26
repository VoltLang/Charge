// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

import watt.io.monotonic;

import io = watt.io;

import charge.util.hash;

enum Count : u32 = 2u * 1024u * 1024u;
//enum Count : u32 = 100000;


struct AAWrapper
{
	aa: bool[u32];

	fn setup(size_t)
	{

	}

	fn add(key: u32, value: bool)
	{
		aa[key] = value;
	}

	fn remove(key: u32)
	{
		aa.remove(key);
	}

	fn getOrInit(key: u32) bool
	{
		r := key in aa;
		if (r !is null) {
			return *r;
		} else {
			return false;
		}
	}
}

struct Test!(Map, name: string) {

	global fn test()
	{
		io.output.writefln("Testing: %s", name);
		io.output.flush();

		thenSetup := ticks();
		map: Map;
		map.setup(0);
		nowSetup := ticks();

		thenAdd := ticks();
		foreach (i; 0u .. Count) {
			map.add(i, true);
		}
		nowAdd := ticks();

		removed: size_t;
		thenRemove := ticks();
		for (u32 i; i < Count; i += 2u) {
			removed++;
			map.remove(i);
		}
		nowRemove := ticks();

		haveFound: size_t;
		thenFind := ticks();
		for (u32 i; i < Count; i++) {
			if (map.getOrInit(i)) {
				haveFound++;
			}
		}
		nowFind := ticks();

		shouldFind := Count - removed;
		calcSetup := convClockFreq(nowSetup - thenSetup, ticksPerSecond, 1_000_000_000);
		calcAdd := convClockFreq(nowAdd - thenAdd, ticksPerSecond, 1_000_000_000);
		calcFind := convClockFreq(nowFind - thenFind, ticksPerSecond, 1_000_000_000);
		calcRemove := convClockFreq(nowRemove - thenRemove, ticksPerSecond, 1_000_000_000);
		io.output.writefln("\tadded %s, removed %s", Count, removed);
		io.output.writefln("\tshould find %s, found %s (%s)", shouldFind, haveFound, shouldFind == haveFound);
		io.output.writefln("\tsetup:  %3s'%03s'%03sns", calcSetup / 1_000_000, (calcSetup / 1_000) % 1_000, calcSetup % 1000);
		io.output.writefln("\tadd:    %3s'%03s'%03sns", calcAdd / 1_000_000, (calcAdd / 1_000) % 1_000, calcAdd % 1000);
		io.output.writefln("\tremove: %3s'%03s'%03sns", calcRemove / 1_000_000, (calcRemove / 1_000) % 1_000, calcRemove % 1000);
		io.output.writefln("\tfind:   %3s'%03s'%03sns", calcFind / 1_000_000, (calcFind / 1_000) % 1_000, calcFind % 1000);
		perAdd := cast(u64)(cast(f64)calcAdd / Count * 1_000.0);
		perFind := cast(u64)(cast(f64)calcFind / Count * 1_000.0);
		perRemove := cast(u64)(cast(f64)calcRemove / removed * 1_000.0);
		io.output.writefln("\tper add       %5s'%03sps", perAdd / 1_000, perAdd % 1_000);
		io.output.writefln("\tper find      %5s'%03sps", perFind / 1_000, perFind % 1_000);
		io.output.writefln("\tper remove    %5s'%03sps", perRemove / 1_000, perRemove % 1_000);
		io.output.flush();
	}
}

struct Test1 = mixin Test!(AAWrapper, "vrt AA");
struct Test2 = mixin Test!(HashMapU32BoolFast, "HashSet - Fast");
struct Test3 = mixin Test!(HashMapU32BoolRobust, "HashSet - Robust");

fn main() int
{
	Test1.test();
	Test2.test();
	Test3.test();
	return 0;
}
