// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Quatf.
 */
module charge.math.quat;

import watt.math;
import io = watt.io;

import charge.math.vector;


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
	 * Return a new quat which is this rotation rotated by the given rotation.
	 */
	Quatf opMul(Quatf quat)
	{
		Quatf result;

		result.w = w*quat.w - x*quat.x - y*quat.y - z*quat.z;
		result.x = w*quat.x + x*quat.w + y*quat.z - z*quat.y;
		result.y = w*quat.y - x*quat.z + y*quat.w + z*quat.x;
		result.z = w*quat.z + x*quat.y - y*quat.x + z*quat.w;

		return result;
	}

	/**
	 * Return a copy of the given vector but rotated by this rotation.
	 */
	Vector3f opMul(Vector3f vec)
	{
		Quatf q = {vec.x * x + vec.y * y + vec.z * z,
		           vec.x * w + vec.z * y - vec.y * z,
		           vec.y * w + vec.x * z - vec.z * x,
		           vec.z * w + vec.y * x - vec.x * y};

		Vector3f v = {w * q.x + x * q.w + y * q.z - z * q.y,
		              w * q.y + y * q.w + z * q.x - x * q.z,
		              w * q.z + z * q.w + x * q.y - y * q.x};

		return v;
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
