// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for Matrix4x4d.
 */
module charge.math.matrix;

import watt.math : sin, cos, PI, PIf;
import charge.math.quat;
import charge.math.point;
import charge.math.vector;


struct Matrix3x3f
{
public:
	a: f32[9];


public:
	fn setToIdentity()
	{
		foreach(ref v; a[1 .. $]) {
			v = 0.f;
		}
		a[0] = 1.f;
		a[4] = 1.f;
		a[8] = 1.f;
	}

	fn setTo(ref mat: Matrix3x3d)
	{
		foreach (i, ref d; mat.u.a) {
			a[i] = cast(f32)d;
		}
	}

	fn setToAndTranspose(ref mat: Matrix3x3d)
	{
		a[0] = cast(f32)mat.u.a[0];
		a[3] = cast(f32)mat.u.a[1];
		a[6] = cast(f32)mat.u.a[2];

		a[1] = cast(f32)mat.u.a[3];
		a[4] = cast(f32)mat.u.a[4];
		a[7] = cast(f32)mat.u.a[5];

		a[2] = cast(f32)mat.u.a[6];
		a[5] = cast(f32)mat.u.a[7];
		a[8] = cast(f32)mat.u.a[8];
	}

	@property fn ptr() f32* { return a.ptr; }
}

struct Matrix4x4f
{
public:
	a: f32[16];


public:
	fn setToIdentity()
	{
		foreach(ref v; a[1 .. $]) {
			v = 0.f;
		}
		a[0]  = 1.f;
		a[5]  = 1.f;
		a[10] = 1.f;
		a[15] = 1.f;
	}

	fn setFrom(ref mat: Matrix4x4d)
	{
		foreach (i, ref d; mat.u.a) {
			a[i] = cast(f32)d;
		}
	}

	fn setToAndTranspose(ref mat: Matrix4x4d)
	{
		a[ 0] = cast(f32)mat.u.a[ 0];
		a[ 4] = cast(f32)mat.u.a[ 1];
		a[ 8] = cast(f32)mat.u.a[ 2];
		a[12] = cast(f32)mat.u.a[ 3];
		a[ 1] = cast(f32)mat.u.a[ 4];
		a[ 5] = cast(f32)mat.u.a[ 5];
		a[ 9] = cast(f32)mat.u.a[ 6];
		a[13] = cast(f32)mat.u.a[ 7];
		a[ 2] = cast(f32)mat.u.a[ 8];
		a[ 6] = cast(f32)mat.u.a[ 9];
		a[10] = cast(f32)mat.u.a[10];
		a[14] = cast(f32)mat.u.a[11];
		a[ 3] = cast(f32)mat.u.a[12];
		a[ 7] = cast(f32)mat.u.a[13];
		a[11] = cast(f32)mat.u.a[14];
		a[15] = cast(f32)mat.u.a[15];
	}

	fn setToMultiply(ref l: Matrix4x4d, ref r: Matrix4x4d)
	{
		foreach (i; 0 .. 4) {
			l0 := l.u.m[i][0];
			l1 := l.u.m[i][1];
			l2 := l.u.m[i][2];
			l3 := l.u.m[i][3];
			a[i * 4 + 0] = cast(f32)(l0 * r.u.m[0][0] + l1 * r.u.m[1][0] + l2 * r.u.m[2][0] + l3 * r.u.m[3][0]);
			a[i * 4 + 1] = cast(f32)(l0 * r.u.m[0][1] + l1 * r.u.m[1][1] + l2 * r.u.m[2][1] + l3 * r.u.m[3][1]);
			a[i * 4 + 2] = cast(f32)(l0 * r.u.m[0][2] + l1 * r.u.m[1][2] + l2 * r.u.m[2][2] + l3 * r.u.m[3][2]);
			a[i * 4 + 3] = cast(f32)(l0 * r.u.m[0][3] + l1 * r.u.m[1][3] + l2 * r.u.m[2][3] + l3 * r.u.m[3][3]);
		}
	}

	fn setToMultiplyAndTranspose(ref l: Matrix4x4d, ref r: Matrix4x4d)
	{
		foreach (i; 0 .. 4) {
			l0 := l.u.m[i][0];
			l1 := l.u.m[i][1];
			l2 := l.u.m[i][2];
			l3 := l.u.m[i][3];
			a[i +  0] = cast(f32)(l0 * r.u.m[0][0] + l1 * r.u.m[1][0] + l2 * r.u.m[2][0] + l3 * r.u.m[3][0]);
			a[i +  4] = cast(f32)(l0 * r.u.m[0][1] + l1 * r.u.m[1][1] + l2 * r.u.m[2][1] + l3 * r.u.m[3][1]);
			a[i +  8] = cast(f32)(l0 * r.u.m[0][2] + l1 * r.u.m[1][2] + l2 * r.u.m[2][2] + l3 * r.u.m[3][2]);
			a[i + 12] = cast(f32)(l0 * r.u.m[0][3] + l1 * r.u.m[1][3] + l2 * r.u.m[2][3] + l3 * r.u.m[3][3]);
		}
	}

	@property fn ptr() f32* { return a.ptr; }
}

struct Matrix3x3d
{
public:
	union Union {
		m: f64[3][3];
		vecs: Vector3d[3];
		a: f64[9];
	}
	u: Union;


public:
	fn setToIdentity()
	{
		u.m[0][0] = 1.0;
		u.m[0][1] = 0.0;
		u.m[0][2] = 0.0;

		u.m[1][0] = 0.0;
		u.m[1][1] = 1.0;
		u.m[1][2] = 0.0;

		u.m[2][0] = 0.0;
		u.m[2][1] = 0.0;
		u.m[2][2] = 1.0;
	}

	fn setTo(ref mat: Matrix4x4d)
	{
		u.m[0][0] = mat.u.m[0][0];
		u.m[0][1] = mat.u.m[0][1];
		u.m[0][2] = mat.u.m[0][2];

		u.m[1][0] = mat.u.m[1][0];
		u.m[1][1] = mat.u.m[1][1];
		u.m[1][2] = mat.u.m[1][2];

		u.m[2][0] = mat.u.m[2][0];
		u.m[2][1] = mat.u.m[2][1];
		u.m[2][2] = mat.u.m[2][2];
	}

	fn setToInverse(ref mat: Matrix4x4d)
	{
		this.setTo(ref mat);
		this.inverseThis();
	}

	fn inverseThis()
	{
		t0 := u.m[1][1] * u.m[2][2] - u.m[2][1] * u.m[1][2];
		t1 := u.m[2][1] * u.m[0][2] - u.m[0][1] * u.m[2][2];
		t2 := u.m[0][1] * u.m[1][2] - u.m[1][1] * u.m[0][2];

		t3 := u.m[2][0] * u.m[1][2] - u.m[1][0] * u.m[2][2];
		t4 := u.m[0][0] * u.m[2][2] - u.m[2][0] * u.m[0][2];
		t5 := u.m[1][0] * u.m[0][2] - u.m[0][0] * u.m[1][2];

		t6 := u.m[1][0] * u.m[2][1] - u.m[2][0] * u.m[1][1];
		t7 := u.m[2][0] * u.m[0][1] - u.m[0][0] * u.m[2][1];
		t8 := u.m[0][0] * u.m[1][1] - u.m[1][0] * u.m[0][1];

		det := u.m[0][0] * t0 + u.m[0][1] * t3 + u.m[0][2] * t6;

		u.a[0] = t0 / det;
		u.a[1] = t1 / det;
		u.a[2] = t2 / det;
		u.a[3] = t3 / det;
		u.a[4] = t4 / det;
		u.a[5] = t5 / det;
		u.a[6] = t6 / det;
		u.a[7] = t7 / det;
		u.a[8] = t8 / det;
	}

	fn toString() string
	{
		return u.vecs[0].toString() ~ "\n" ~
			u.vecs[1].toString() ~ "\n" ~
			u.vecs[2].toString();
	}
}

struct Matrix4x4d
{
public:
	union Union {
		m: f64[4][4];
		a: f64[16];
	}
	u: Union;


public:
	fn setToIdentity()
	{
		u.m[0][0] = 1.0;
		foreach(ref v; u.a[1 .. $]) {
			v = 0.0;
		}
		u.m[1][1] = 1.0;
		u.m[2][2] = 1.0;
		u.m[3][3] = 1.0;
	}

	fn setToModel(ref p: Point3f, ref q: Quatf)
	{
		qx: f64 = q.x;
		qy: f64 = q.y;
		qz: f64 = q.z;
		qw: f64 = q.w;

		u.m[0][0] = 1 - 2 * qy * qy - 2 * qz * qz;
		u.m[0][1] =     2 * qx * qy - 2 * qw * qz;
		u.m[0][2] =     2 * qx * qz + 2 * qw * qy;
		u.m[0][3] = p.x;

		u.m[1][0] =     2 * qx * qy + 2 * qw * qz;
		u.m[1][1] = 1 - 2 * qx * qx - 2 * qz * qz;
		u.m[1][2] =     2 * qy * qz - 2 * qw * qx;
		u.m[1][3] = p.y;

		u.m[2][0] =     2 * qx * qz - 2 * qw * qy;
		u.m[2][1] =     2 * qy * qz + 2 * qw * qx;
		u.m[2][2] = 1 - 2 * qx * qx - 2 * qy * qy;
		u.m[2][3] = p.z;

		u.m[3][0] = 0.0;
		u.m[3][1] = 0.0;
		u.m[3][2] = 0.0;
		u.m[3][3] = 1.0;
	}

	fn setToOrtho(left: f64, right: f64,
	              bottom: f64, top: f64,
	              nearval: f64, farval: f64)
	{
		xAdd := right + left;
		u.a[ 0] = 2.0 / (right - left);
		u.a[ 1] = 0.0;
		u.a[ 2] = 0.0;
		u.a[ 3] = xAdd == 0.0 ? 0.0 : -xAdd / (right - left);

		yAdd := top + bottom;
		u.a[ 4] = 0.0;
		u.a[ 5] = 2.0 / (top - bottom);
		u.a[ 6] = 0.0;
		u.a[ 7] = yAdd == 0.0 ? 0.0 : -yAdd / (top - bottom);

		zAdd := farval + nearval;
		u.a[ 8] = 0.0;
		u.a[ 9] = 0.0;
		u.a[10] = -2.0 / (farval - nearval);
		u.a[11] = zAdd == 0.0 ? 0.0 : -zAdd / (farval - nearval);

		u.a[12] = 0.0;
		u.a[13] = 0.0;
		u.a[14] = 0.0;
		u.a[15] = 1.0;
	}

	/*!
	 * Sets the matrix to a lookAt matrix looking at eye + rot * forward.
	 *
	 * Similar to gluLookAt.
	 */
	fn setToLookFrom(ref eye: Point3f, ref rot: Quatf)
	{
		qx: f64 = -rot.x;
		qy: f64 = -rot.y;
		qz: f64 = -rot.z;
		qw: f64 =  rot.w;

		px: f64 = -eye.x;
		py: f64 = -eye.y;
		pz: f64 = -eye.z;

		u.m[0][0] = 1.0 - 2.0 * qy * qy - 2.0 * qz * qz;
		u.m[0][1] =       2.0 * qx * qy - 2.0 * qw * qz;
		u.m[0][2] =       2.0 * qx * qz + 2.0 * qw * qy;
		u.m[0][3] = px * u.m[0][0] + py * u.m[0][1] + pz * u.m[0][2];

		u.m[1][0] =       2.0 * qx * qy + 2.0 * qw * qz;
		u.m[1][1] = 1.0 - 2.0 * qx * qx - 2.0 * qz * qz;
		u.m[1][2] =       2.0 * qy * qz - 2.0 * qw * qx;
		u.m[1][3] = px * u.m[1][0] + py * u.m[1][1] + pz * u.m[1][2];

		u.m[2][0] =       2.0 * qx * qz - 2.0 * qw * qy;
		u.m[2][1] =       2.0 * qy * qz + 2.0 * qw * qx;
		u.m[2][2] = 1.0 - 2.0 * qx * qx - 2.0 * qy * qy;
		u.m[2][3] = px * u.m[2][0] + py * u.m[2][1] + pz * u.m[2][2];

		u.m[3][0] = 0.0;
		u.m[3][1] = 0.0;
		u.m[3][2] = 0.0;
		u.m[3][3] = 1.0;
	}

	/*!
	 * Sets the matrix to the same as gluPerspective does.
	 */
	fn setToPerspective(fovy: f64, aspect: f64, near: f64, far: f64)
	{
		sine, cotangent, delta: f64;
		radians := (fovy / 2.0) * (PI / 180.0);

		delta = far - near;
		sine = sin(radians);

		if ((delta == 0) || (sine == 0) || (aspect == 0)) {
			return;
		}

		cotangent = cos(radians) / sine;

		u.m[0][0] = cotangent / aspect;
		u.m[0][1] = 0.0;
		u.m[0][2] = 0.0;
		u.m[0][3] = 0.0;

		u.m[1][0] = 0.0;
		u.m[1][1] = cotangent;
		u.m[1][2] = 0.0;
		u.m[1][3] = 0.0;

		u.m[2][0] = 0.0;
		u.m[2][1] = 0.0;
		u.m[2][2] = -(far + near) / delta;
		u.m[2][3] = -2.0 * near * far / delta;

		u.m[3][0] = 0.0;
		u.m[3][1] = 0.0;
		u.m[3][2] = -1.0;
		u.m[3][3] = 0.0;
	}

	fn opMul(ref point: Point3f) Point3f
	{
		px: f64 = point.x; py: f64 = point.y; pz: f64 = point.z;
		x := px * u.m[0][0] + py * u.m[0][1] + pz * u.m[0][2] + u.m[0][3];
		y := px * u.m[1][0] + py * u.m[1][1] + pz * u.m[1][2] + u.m[1][3];
		z := px * u.m[2][0] + py * u.m[2][1] + pz * u.m[2][2] + u.m[2][3];
		return Point3f.opCall(cast(f32)x, cast(f32)y, cast(f32)z);
	}

	fn opDiv(ref point: Point3f) Point3f
	{
		px: f64 = point.x; py: f64 = point.y; pz: f64 = point.z;
		x := px * u.m[0][0] + py * u.m[0][1] + pz * u.m[0][2] + u.m[0][3];
		y := px * u.m[1][0] + py * u.m[1][1] + pz * u.m[1][2] + u.m[1][3];
		z := px * u.m[2][0] + py * u.m[2][1] + pz * u.m[2][2] + u.m[2][3];
		w := px * u.m[3][0] + py * u.m[3][1] + pz * u.m[3][2] + u.m[3][3];

		x /= w;
		y /= w;
		z /= w;

		return Point3f.opCall(cast(f32)x, cast(f32)y, cast(f32)z);
	}

	fn setToMultiply(ref l: Matrix4x4d, ref r: Matrix4x4d)
	{
		foreach (i; 0 .. 4) {
			l0 := l.u.m[i][0];
			l1 := l.u.m[i][1];
			l2 := l.u.m[i][2];
			l3 := l.u.m[i][3];
			u.m[i][0] = l0 * r.u.m[0][0] + l1 * r.u.m[1][0] + l2 * r.u.m[2][0] + l3 * r.u.m[3][0];
			u.m[i][1] = l0 * r.u.m[0][1] + l1 * r.u.m[1][1] + l2 * r.u.m[2][1] + l3 * r.u.m[3][1];
			u.m[i][2] = l0 * r.u.m[0][2] + l1 * r.u.m[1][2] + l2 * r.u.m[2][2] + l3 * r.u.m[3][2];
			u.m[i][3] = l0 * r.u.m[0][3] + l1 * r.u.m[1][3] + l2 * r.u.m[2][3] + l3 * r.u.m[3][3];
		}
	}

	fn transpose()
	{
		temp: Matrix4x4d;

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

	fn inverse()
	{
		fA0 := u.a[ 0] * u.a[ 5] - u.a[ 1] * u.a[ 4];
		fA1 := u.a[ 0] * u.a[ 6] - u.a[ 2] * u.a[ 4];
		fA2 := u.a[ 0] * u.a[ 7] - u.a[ 3] * u.a[ 4];
		fA3 := u.a[ 1] * u.a[ 6] - u.a[ 2] * u.a[ 5];
		fA4 := u.a[ 1] * u.a[ 7] - u.a[ 3] * u.a[ 5];
		fA5 := u.a[ 2] * u.a[ 7] - u.a[ 3] * u.a[ 6];
		fB0 := u.a[ 8] * u.a[13] - u.a[ 9] * u.a[12];
		fB1 := u.a[ 8] * u.a[14] - u.a[10] * u.a[12];
		fB2 := u.a[ 8] * u.a[15] - u.a[11] * u.a[12];
		fB3 := u.a[ 9] * u.a[14] - u.a[10] * u.a[13];
		fB4 := u.a[ 9] * u.a[15] - u.a[11] * u.a[13];
		fB5 := u.a[10] * u.a[15] - u.a[11] * u.a[14];

		f64 fDet = fA0 * fB5 - fA1 * fB4 + fA2 * fB3 + fA3 * fB2 - fA4 * fB1 + fA5 * fB0;

		temp: f64[16];
		temp[ 0] = + u.a[ 5] * fB5 - u.a[ 6] * fB4 + u.a[ 7] * fB3;
		temp[ 4] = - u.a[ 4] * fB5 + u.a[ 6] * fB2 - u.a[ 7] * fB1;
		temp[ 8] = + u.a[ 4] * fB4 - u.a[ 5] * fB2 + u.a[ 7] * fB0;
		temp[12] = - u.a[ 4] * fB3 + u.a[ 5] * fB1 - u.a[ 6] * fB0;
		temp[ 1] = - u.a[ 1] * fB5 + u.a[ 2] * fB4 - u.a[ 3] * fB3;
		temp[ 5] = + u.a[ 0] * fB5 - u.a[ 2] * fB2 + u.a[ 3] * fB1;
		temp[ 9] = - u.a[ 0] * fB4 + u.a[ 1] * fB2 - u.a[ 3] * fB0;
		temp[13] = + u.a[ 0] * fB3 - u.a[ 1] * fB1 + u.a[ 2] * fB0;
		temp[ 2] = + u.a[13] * fA5 - u.a[14] * fA4 + u.a[15] * fA3;
		temp[ 6] = - u.a[12] * fA5 + u.a[14] * fA2 - u.a[15] * fA1;
		temp[10] = + u.a[12] * fA4 - u.a[13] * fA2 + u.a[15] * fA0;
		temp[14] = - u.a[12] * fA3 + u.a[13] * fA1 - u.a[14] * fA0;
		temp[ 3] = - u.a[ 9] * fA5 + u.a[10] * fA4 - u.a[11] * fA3;
		temp[ 7] = + u.a[ 8] * fA5 - u.a[10] * fA2 + u.a[11] * fA1;
		temp[11] = - u.a[ 8] * fA4 + u.a[ 9] * fA2 - u.a[11] * fA0;
		temp[15] = + u.a[ 8] * fA3 - u.a[ 9] * fA1 + u.a[10] * fA0;

		fInvDet := 1.0 / fDet;

		u.a[ 0] = temp[ 0] * fInvDet;
		u.a[ 1] = temp[ 1] * fInvDet;
		u.a[ 2] = temp[ 2] * fInvDet;
		u.a[ 3] = temp[ 3] * fInvDet;
		u.a[ 4] = temp[ 4] * fInvDet;
		u.a[ 5] = temp[ 5] * fInvDet;
		u.a[ 6] = temp[ 6] * fInvDet;
		u.a[ 7] = temp[ 7] * fInvDet;
		u.a[ 8] = temp[ 8] * fInvDet;
		u.a[ 9] = temp[ 9] * fInvDet;
		u.a[10] = temp[10] * fInvDet;
		u.a[11] = temp[11] * fInvDet;
		u.a[12] = temp[12] * fInvDet;
		u.a[13] = temp[13] * fInvDet;
		u.a[14] = temp[14] * fInvDet;
		u.a[15] = temp[15] * fInvDet;
	}

	@property fn ptr() f64* { return u.a.ptr; }
}
