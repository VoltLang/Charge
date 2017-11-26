// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for calculating a average over time.
 */
module charge.math.average;


struct Average
{
	samples: ulong[32];
	size_t pos;

	fn add(value: ulong)
	{
		samples[pos] = value;
		pos = (pos + 1) % samples.length;
	}

	fn calc() ulong
	{
		sum: ulong;
		foreach (v; samples) {
			sum += v;
		}
		return sum / samples.length;
	}
}
