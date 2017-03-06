// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.util.counters;

import watt.text.sink;
import watt.text.format;

import math = charge.math;
import charge.gfx;


class Counters
{
public:
	names: string[];
	samples: math.Average[];
	timers: GfxTimer[];


public:
	this(names: string[]...)
	{
		assert(names.length > 0);

		this.names = names;
		timers = new GfxTimer[](names.length);
		samples = new math.Average[](names.length);

		foreach (ref t; timers) {
			t.setup();
		}
	}

	fn close()
	{
		foreach (ref t; timers) {
			t.close();
		}
	}

	fn start(n: size_t)
	{
		val: ulong;
		if (timers[n].getValue(out val)) {
			samples[n].add(val);
		}
		timers[n].start();
	}

	fn stop(n: size_t)
	{
		timers[n].stop();
	}

	fn print(sink: Sink)
	{
		total: GLuint64;
		foreach (i, ref timer; timers) {
			v: GLuint64;
			if (timer.getValue(out v)) {
				samples[i].add(v);
			}

			val := samples[i].calc();
			total += val;
			val /= (1_000_000_000 / 1_000_000u);
			format(sink, " % 14s:% 2s.%03sms\n", names[i], val / 1000, val % 1000);
		}
		total /= (1_000_000_000 / 1_000_000u);
		format(sink, " % 14s:% 2s.%03sms\n", "total", total / 1000, total % 1000);
	}
}
