// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for Quatf.
 */
module charge.math.quat;

import watt.math;
import io = watt.io;

import charge.math.vector;


struct Quatf
{
public:
	x, y, z, w: f32;


public:
	global fn opCall() Quatf
	{
		q: Quatf = { 0.f, 0.f, 0.f, 1.f };
		return q;
	}

	global fn opCall(w: f32, x: f32, y: f32, z: f32) Quatf
	{
		q: Quatf = { x, y, z, w };
		return q;
	}

	/*!
	 * Convert from Euler (and Tait-Bryan) angles to Quaternion.
	 *
	 * Note in charge the Y axis is and Z points out from the screen.
	 *
	 * @arg heading, TB: yaw, Euler: rotation around the Y axis.
	 * @arg pitch, TB: pitch, Euler: rotation around the X axis.
	 * @arg roll, TB: roll, Euler: rotation around the Z axis.
	 * @see http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
	 */
	global fn opCall(heading: f32, pitch: f32, roll: f32) Quatf
	{
		sinPitch := sin(heading * 0.5f);
		cosPitch := cos(heading * 0.5f);
		sinYaw := sin(roll * 0.5f);
		cosYaw := cos(roll * 0.5f);
		sinRoll := sin(pitch * 0.5f);
		cosRoll := cos(pitch * 0.5f);
		cosPitchCosYaw := cosPitch * cosYaw;
		sinPitchSinYaw := sinPitch * sinYaw;
		q: Quatf;
		q.x = sinRoll * cosPitchCosYaw     - cosRoll * sinPitchSinYaw;
		q.y = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw;
		q.z = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw;
		q.w = cosRoll * cosPitchCosYaw     + sinRoll * sinPitchSinYaw;

		q.normalize();
		return q;
	}

	/*!
	 * Return a new quat which is this rotation rotated by the given rotation.
	 */
	fn opMul(quat: Quatf) Quatf
	{
		result: Quatf;

		result.w = w*quat.w - x*quat.x - y*quat.y - z*quat.z;
		result.x = w*quat.x + x*quat.w + y*quat.z - z*quat.y;
		result.y = w*quat.y - x*quat.z + y*quat.w + z*quat.x;
		result.z = w*quat.z + x*quat.y - y*quat.x + z*quat.w;

		return result;
	}

	/*!
	 * Return a copy of the given vector but rotated by this rotation.
	 */
	fn opMul(vec: Vector3f) Vector3f
	{
		q: Quatf = {vec.x * w + vec.z * y - vec.y * z,
		            vec.y * w + vec.x * z - vec.z * x,
		            vec.z * w + vec.y * x - vec.x * y,
		            vec.x * x + vec.y * y + vec.z * z};

		v: Vector3f = {w * q.x + x * q.w + y * q.z - z * q.y,
		               w * q.y + y * q.w + z * q.x - x * q.z,
		               w * q.z + z * q.w + x * q.y - y * q.x};

		return v;
	}

	/*!
	 * Normalize the rotation, often not needed when using only the
	 * inbuilt functions.
	 */
	fn normalize()
	{
		len: float = length;
		if (len == 0.0) {
			return;
		}

		w /= len;
		x /= len;
		y /= len;
		z /= len;
	}

	const @property fn length() f32
	{
		return sqrt(x*x + y*y + z*z + w*w);
	}
}
