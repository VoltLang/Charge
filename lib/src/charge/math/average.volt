// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for calculating a average over time.
 *
 * @ingroup Math
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
