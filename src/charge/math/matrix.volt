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
		float[4][4] m;
		float[16] a;
	}
	Union u;

public:

	void setToIdentity()
	{
		u.m[0][0] = 1.0f;
		foreach(ref v; u.a[1 .. $]) {
			v = 0.0f;
		}
		u.m[1][1] = 1.0f;
		u.m[2][2] = 1.0f;
		u.m[3][3] = 1.0f;
	}

	void setToOrtho(float left, float right,
	                float bottom, float top,
	                float nearval, float farval)
	{
		float xAdd = right + left;
		u.a[ 0] = 2.0f / (right - left);
		u.a[ 1] = 0.0f;
		u.a[ 2] = 0.0f;
		u.a[ 3] = xAdd == 0.0f ? 0.0f : -xAdd / (right - left);

		float yAdd = top + bottom;
		u.a[ 4] = 0.0f;
		u.a[ 5] = 2.0f / (top - bottom);
		u.a[ 6] = 0.0f;
		u.a[ 7] = yAdd == 0.0f ? 0.0f : -yAdd / (top - bottom);

		float zAdd = farval + nearval;
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
	void setToLookFrom(ref Point3f eye, ref Quatf rot)
	{
		Point3f p;
		Quatf q;

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
	void setToPerspective(float fovy, float aspect, float near, float far, bool flip = false)
	{
		float sine, cotangent, delta;
		float radians = fovy / 2.f * PIf / 180.f;

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
		u.m[1][1] = flip ? -cotangent : cotangent;
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

	void setToMultiply(ref Matrix4x4f b)
	{
		for(int i; i < 4; i++) {
			float a0 = u.m[i][0], a1 = u.m[i][1], a2 = u.m[i][2], a3 = u.m[i][3];
			u.m[i][0] = a0 * b.u.m[0][0] + a1 * b.u.m[1][0] + a2 * b.u.m[2][0] + a3 * b.u.m[3][0];
			u.m[i][1] = a0 * b.u.m[0][1] + a1 * b.u.m[1][1] + a2 * b.u.m[2][1] + a3 * b.u.m[3][1];
			u.m[i][2] = a0 * b.u.m[0][2] + a1 * b.u.m[1][2] + a2 * b.u.m[2][2] + a3 * b.u.m[3][2];
			u.m[i][3] = a0 * b.u.m[0][3] + a1 * b.u.m[1][3] + a2 * b.u.m[2][3] + a3 * b.u.m[3][3];
		}
	}

	void transpose()
	{
		Matrix4x4f temp;

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

	@property float* ptr() { return u.a.ptr; }
}
