// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Point3f.
 *
 * @ingroup Math
 */
module charge.math.point;

import watt.text.format;
import charge.math.vector;


/*!
 * Point in 3D space.
 *
 * @ingroup Math
 */
struct Point3f
{
public:
	x, y, z: f32;


public:
	static fn opCall() Point3f
	{
		p: Point3f = { 0.0f, 0.0f, 0.0f };
		return p;
	}

	static fn opCall(x: f32, y: f32, z: f32) Point3f
	{
		p: Point3f = { x, y, z };
		return p;
	}

	static fn opCall(vec: Vector3f) Point3f
	{
		p: Point3f = { vec.x, vec.y, vec.z };
		return p;
	}

	static fn opCall(vec: f32[3]) Point3f
	{
		p: Point3f = { vec[0], vec[1], vec[2] };
		return p;
	}

	static fn opCall(vec: f32[4]) Point3f
	{
		p: Point3f = { vec[0], vec[1], vec[2] };
		return p;
	}

	@property fn ptr() float*
	{
		return &x;
	}

/+
	double opIndex(uint index) const
	{
		return (&x)[index];
	}
+/

	fn opAdd(vec: Vector3f) Point3f
	{
		return Point3f.opCall(x + vec.x, y + vec.y, z + vec.z);
	}

	fn opAddAssign(v: Vector3f) Point3f
	{
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}

	fn opSub(p: Point3f) Vector3f
	{
		return Vector3f.opCall(x - p.x, y - p.y, z - p.z);
	}

	fn opSub(v: Vector3f) Point3f
	{
		return Point3f.opCall(x - v.x, y - v.y, z - v.z);
	}

	fn opNeg() Point3f
	{
		return Point3f.opCall(-x, -y, -z);
	}

	fn opSubAssign(v: Vector3f) Point3f
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return this;
	}

/+
	void floor()
	{
		x = cast(double).floor(x);
		y = cast(double).floor(y);
		z = cast(double).floor(z);
	}
+/

	fn vec() Vector3f
	{
		return Vector3f.opCall(this);
	}

	fn toString() string
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}
