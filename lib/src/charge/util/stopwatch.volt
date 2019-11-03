// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module charge.util.stopwatch;

import core.rt.misc;
import watt.io.monotonic;


struct StopWatch
{
public:
	startTicks: i64;
	stopTicks: i64;


public:
	fn start() i64
	{
		return stopTicks = startTicks = ticks();
	}

	fn fromInit() i64
	{
 		return stopTicks = startTicks = vrt_monotonic_ticks_at_init();
 	}

	fn startAndStop(ref last: StopWatch) i64
	{
		return stopTicks = startTicks = last.stop();
	}

	fn stop() i64
	{
		return stopTicks = ticks();
	}

	@property fn microseconds() i64
	{
		return convClockFreq(stopTicks - startTicks, ticksPerSecond, 1_000_000);
	}

	@property fn milliseconds() i64
	{
		return convClockFreq(stopTicks - startTicks, ticksPerSecond, 1_000);
	}
}
