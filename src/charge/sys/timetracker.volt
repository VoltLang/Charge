// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/*!
 * Source file for TimeTracker.
 */
module charge.sys.tracker;

import watt.io.monotonic;


final class TimeTracker
{
private:
	mName: string;
	mThen: i64;
	mAccumilated: i64;

	global gStack: TimeTracker[16];
	global gTop: size_t;

	global gKeepers: TimeTracker[];
	global gLastCalc: i64;


public:
	this(name: string)
	{
		this.mName = name;
		gKeepers ~= this;
	}

	fn start()
	{
		now := getMicros();
		gStack[gTop].account(now);
		mThen = now;

		gStack[++gTop] = this;
	}

	fn stop()
	{
		now := getMicros();
		account(now);

		assert(gStack[gTop] is this);
		gStack[gTop--] = null;
		gStack[gTop].mThen = now;
	}

	global fn calcAll(dgt: dg(string, i64, i64))
	{
		now := getMicros();
		elapsed := now - gLastCalc;
		gLastCalc = now;

		// Make sure everything up till now is accounted for.
		gStack[gTop].account(now);

		foreach(tk; gKeepers) {
			dgt(tk.mName, tk.mAccumilated, elapsed);
			tk.mAccumilated = 0;
		}
	}


private:
	void account(now: i64)
	{
		mAccumilated += now - mThen;
		mThen = now;
	}
}


private:

fn getMicros() i64
{
	return convClockFreq(ticks(), ticksPerSecond, 1_000_000);
}

global this()
{
	TimeTracker.gStack[TimeTracker.gTop] = new TimeTracker("core");
}
