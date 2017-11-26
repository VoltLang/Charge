// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/*!
 * Source file for TimeTracker.
 */
module charge.sys.timetracker;

import watt.io.monotonic;
import watt.text.sink : Sink;
import watt.text.format : format;


final class TimeTracker
{
private:
	mName: string;
	mThen: i64;
	mAccumilated: i64;
	mLastAccumilated: i64;

	global gStack: TimeTracker[16];
	global gTop: size_t;

	global gKeepers: TimeTracker[];
	global gLastThen: i64;
	global gLastElapsed: i64;


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

	global fn getTimings(sink: Sink)
	{
		updateAll();

		div := cast(f64)gLastElapsed / 1000.0;

		foreach(tk; gKeepers) {
			p := cast(u32)(cast(f64)tk.mLastAccumilated / div);
			sink.format("%10s: %2s.%s%%\n", tk.mName, p / 10, p % 10);
		}
	}


private:
	global fn updateAll()
	{
		now := getMicros();
		elapsed := now - gLastThen;

		// Only update 5 times a second.
		if (elapsed < (MicrosPerSeconds / 5)) {
			return;
		}

		// Update where should update.
		gLastThen = now;
		gLastElapsed = elapsed;

		// Make sure everything up till now is accounted for.
		gStack[gTop].account(now);

		foreach(tk; gKeepers) {
			tk.mLastAccumilated = tk.mAccumilated;
			tk.mAccumilated = 0;
		}
	}

	fn account(now: i64)
	{
		mAccumilated += now - mThen;
		mThen = now;
	}
}


private:

enum MicrosPerSeconds = 1_000_000;

fn getMicros() i64
{
	return convClockFreq(ticks(), ticksPerSecond, MicrosPerSeconds);
}

global this()
{
	TimeTracker.gStack[TimeTracker.gTop] = new TimeTracker("core");
}
