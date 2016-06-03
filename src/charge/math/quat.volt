// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Quatf.
 */
module charge.math.quat;

import watt.math;
import io = watt.io;

struct Quatf
{
public:
	float w, x, y, z;


public:
	/**
	 * Convert from Euler (and Tait-Bryan) angles to Quaternion.
	 *
	 * Note in charge the Y axis is and Z points out from the screen.
	 *
	 * @arg heading, TB: yaw, Euler: rotation around the Y axis.
	 * @arg pitch, TB: pitch, Euler: rotation around the X axis.
	 * @arg roll, TB: roll, Euler: rotation around the Z axis.
	 * @see http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
	 */
	global Quatf opCall(float heading, float pitch, float roll)
	{
		float sinPitch = sin(heading * 0.5f);
		float cosPitch = cos(heading * 0.5f);
		float sinYaw = sin(roll * 0.5f);
		float cosYaw = cos(roll * 0.5f);
		float sinRoll = sin(pitch * 0.5f);
		float cosRoll = cos(pitch * 0.5f);
		float cosPitchCosYaw = cosPitch * cosYaw;
		float sinPitchSinYaw = sinPitch * sinYaw;
		Quatf q;
		q.x = sinRoll * cosPitchCosYaw     - cosRoll * sinPitchSinYaw;
		q.y = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw;
		q.z = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw;
		q.w = cosRoll * cosPitchCosYaw     + sinRoll * sinPitchSinYaw;

		q.normalize();
		return q;
	}

	/**
	 * Normalize the rotation, often not needed when using only the
	 * inbuilt functions.
	 */
	void normalize()
	{
		float len = length;
		if (len == 0.0) {
			return;
		}

		w /= len;
		x /= len;
		y /= len;
		z /= len;
	}

	const @property float length()
	{
		return sqrt(w*w + x*x + y*y + z*z);
	}
}
