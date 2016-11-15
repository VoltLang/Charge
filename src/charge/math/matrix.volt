// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Matrix4x4f.
 */
module charge.math.matrix;

import watt.math : sin, cos, PIf;
import charge.math.quat;
import charge.math.point;


struct Matrix4x4f
{
public:
	union Union {
		m: float[4][4];
		a: float[16];
	}
	u: Union;

public:

	fn setToIdentity()
	{
		u.m[0][0] = 1.0f;
		foreach(ref v; u.a[1 .. $]) {
			v = 0.0f;
		}
		u.m[1][1] = 1.0f;
		u.m[2][2] = 1.0f;
		u.m[3][3] = 1.0f;
	}

	fn setToOrtho(left: f32, right: f32,
	                bottom: f32, top: f32,
	                nearval: f32, farval: f32)
	{
		xAdd := right + left;
		u.a[ 0] = 2.0f / (right - left);
		u.a[ 1] = 0.0f;
		u.a[ 2] = 0.0f;
		u.a[ 3] = xAdd == 0.0f ? 0.0f : -xAdd / (right - left);

		yAdd := top + bottom;
		u.a[ 4] = 0.0f;
		u.a[ 5] = 2.0f / (top - bottom);
		u.a[ 6] = 0.0f;
		u.a[ 7] = yAdd == 0.0f ? 0.0f : -yAdd / (top - bottom);

		zAdd := farval + nearval;
		u.a[ 8] = 0.0f;
		u.a[ 9] = 0.0f;
		u.a[10] = -2.0f / (farval - nearval);
		u.a[11] = zAdd == 0.0f ? 0.0f : -zAdd / (farval - nearval);

		u.a[12] = 0.0f;
		u.a[13] = 0.0f;
		u.a[14] = 0.0f;
		u.a[15] = 1.0f;
	}

	/**
	 * Sets the matrix to a lookAt matrix looking at eye + rot * forward.
	 *
	 * Similar to gluLookAt.
	 */
	fn setToLookFrom(ref eye: Point3f, ref rot: Quatf)
	{
		p: Point3f;
		q: Quatf;

		q.x = -rot.x;
		q.y = -rot.y;
		q.z = -rot.z;
		q.w =  rot.w;

		p.x = -eye.x;
		p.y = -eye.y;
		p.z = -eye.z;

		u.m[0][0] = 1.f - 2.f * q.y * q.y - 2.f * q.z * q.z;
		u.m[0][1] =       2.f * q.x * q.y - 2.f * q.w * q.z;
		u.m[0][2] =       2.f * q.x * q.z + 2.f * q.w * q.y;
		u.m[0][3] = p.x * u.m[0][0] + p.y * u.m[0][1] + p.z * u.m[0][2];

		u.m[1][0] =       2.f * q.x * q.y + 2.f * q.w * q.z;
		u.m[1][1] = 1.f - 2.f * q.x * q.x - 2.f * q.z * q.z;
		u.m[1][2] =       2.f * q.y * q.z - 2.f * q.w * q.x;
		u.m[1][3] = p.x * u.m[1][0] + p.y * u.m[1][1] + p.z * u.m[1][2];

		u.m[2][0] =       2.f * q.x * q.z - 2.f * q.w * q.y;
		u.m[2][1] =       2.f * q.y * q.z + 2.f * q.w * q.x;
		u.m[2][2] = 1.f - 2.f * q.x * q.x - 2.f * q.y * q.y;
		u.m[2][3] = p.x * u.m[2][0] + p.y * u.m[2][1] + p.z * u.m[2][2];

		u.m[3][0] = 0.0f;
		u.m[3][1] = 0.0f;
		u.m[3][2] = 0.0f;
		u.m[3][3] = 1.0f;
	}

	/**
	 * Sets the matrix to the same as gluPerspective does.
	 */
	fn setToPerspective(fovy: f32, aspect: f32, near: f32, far: f32)
	{
		sine, cotangent, delta: f32;
		radians := (fovy / 2.f) * (PIf / 180.f);

		delta = far - near;
		sine = sin(radians);

		if ((delta == 0) || (sine == 0) || (aspect == 0)) {
			return;
		}

		cotangent = cos(radians) / sine;

		u.m[0][0] = cotangent / aspect;
		u.m[0][1] = 0.f;
		u.m[0][2] = 0.f;
		u.m[0][3] = 0.f;

		u.m[1][0] = 0.f;
		u.m[1][1] = cotangent;
		u.m[1][2] = 0.f;
		u.m[1][3] = 0.f;

		u.m[2][0] = 0.f;
		u.m[2][1] = 0.f;
		u.m[2][2] = -(far + near) / delta;
		u.m[2][3] = -2.f * near * far / delta;

		u.m[3][0] = 0.f;
		u.m[3][1] = 0.f;
		u.m[3][2] = -1.f;
		u.m[3][3] = 0.f;
	}

	fn opMul(point: Point3f) Point3f
	{
		result: Point3f;
		result.x = point.x * u.m[0][0] + point.y * u.m[0][1] + point.z * u.m[0][2] + u.m[0][3];
		result.y = point.x * u.m[1][0] + point.y * u.m[1][1] + point.z * u.m[1][2] + u.m[1][3];
		result.z = point.x * u.m[2][0] + point.y * u.m[2][1] + point.z * u.m[2][2] + u.m[2][3];
		//result.w = point.x * m[3][0] + point.y * m[3][1] + point.z * m[3][2] + m[3][3];
		return result;
	}

	fn opDiv(point: Point3f) Point3f
	{
		result: Point3f;
		result.x = point.x * u.m[0][0] + point.y * u.m[0][1] + point.z * u.m[0][2] + u.m[0][3];
		result.y = point.x * u.m[1][0] + point.y * u.m[1][1] + point.z * u.m[1][2] + u.m[1][3];
		result.z = point.x * u.m[2][0] + point.y * u.m[2][1] + point.z * u.m[2][2] + u.m[2][3];
		w:   f32 = point.x * u.m[3][0] + point.y * u.m[3][1] + point.z * u.m[3][2] + u.m[3][3];

		result.x /= w;
		result.y /= w;
		result.z /= w;

		return result;
	}

	fn setToMultiply(ref b: Matrix4x4f)
	{
		foreach (i; 0 .. 4) {
			a0 := u.m[i][0];
			a1 := u.m[i][1];
			a2 := u.m[i][2];
			a3 := u.m[i][3];
			u.m[i][0] = a0 * b.u.m[0][0] + a1 * b.u.m[1][0] + a2 * b.u.m[2][0] + a3 * b.u.m[3][0];
			u.m[i][1] = a0 * b.u.m[0][1] + a1 * b.u.m[1][1] + a2 * b.u.m[2][1] + a3 * b.u.m[3][1];
			u.m[i][2] = a0 * b.u.m[0][2] + a1 * b.u.m[1][2] + a2 * b.u.m[2][2] + a3 * b.u.m[3][2];
			u.m[i][3] = a0 * b.u.m[0][3] + a1 * b.u.m[1][3] + a2 * b.u.m[2][3] + a3 * b.u.m[3][3];
		}
	}

	fn transpose()
	{
		temp: Matrix4x4f;

		temp.u.a[ 0] = u.a[ 0];
		temp.u.a[ 1] = u.a[ 4];
		temp.u.a[ 2] = u.a[ 8];
		temp.u.a[ 3] = u.a[12];
		temp.u.a[ 4] = u.a[ 1];
		temp.u.a[ 5] = u.a[ 5];
		temp.u.a[ 6] = u.a[ 9];
		temp.u.a[ 7] = u.a[13];
		temp.u.a[ 8] = u.a[ 2];
		temp.u.a[ 9] = u.a[ 6];
		temp.u.a[10] = u.a[10];
		temp.u.a[11] = u.a[14];
		temp.u.a[12] = u.a[ 3];
		temp.u.a[13] = u.a[ 7];
		temp.u.a[14] = u.a[11];
		temp.u.a[15] = u.a[15];

		this = temp;
	}

	@property fn ptr() float* { return u.a.ptr; }
}
