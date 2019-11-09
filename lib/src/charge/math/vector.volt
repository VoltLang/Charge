// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Vector3f.
 *
 * @ingroup Math
 */
module charge.math.vector;

import watt.math;
import watt.text.format;
import charge.math.point;


/*!
 * Vector in a 3D space. Charge follows the OpenGL convetion for axis
 * so Y+ is up, X+ is right and Z- is forward.
 *
 * @ingroup Math
 */
struct Vector3f
{
public:
	x, y, z: f32;

	global Up: Vector3f =      { 0.0f,  1.0f,  0.0f};
	global Forward: Vector3f = { 0.0f,  0.0f, -1.0f};
	global Left: Vector3f =    {-1.0f,  0.0f,  0.0f};


public:
	global fn opCall(x: f32, y: f32, z: f32) Vector3f
	{
		v: Vector3f = { x, y, z };
		return v;
	}

	global fn opCall(pos: Point3f) Vector3f
	{
		v: Vector3f = { pos.x, pos.y, pos.z };
		return v;
	}

	global fn opCall(ref vec: float[3]) Vector3f
	{
		v: Vector3f = { vec[0], vec[1], vec[2] };
		return v;
	}

	global fn opCall(ref vec: float[4]) Vector3f
	{
		v: Vector3f = { vec[0], vec[1], vec[2] };
		return v;
	}

	@property fn ptr() float*
	{
		return &x;
	}

	fn opAdd(ref pos: Point3f) Point3f
	{
		return Point3f.opCall(pos.x + x, pos.y + y, pos.z + z);
	}

	fn opAdd(ref vec: Vector3f) Vector3f
	{
		return Vector3f.opCall(vec.x + x, vec.y + y, vec.z + z);
	}

	fn opAddAssign(vec: Vector3f)
	{
		x += vec.x;
		y += vec.y;
		z += vec.z;
	}

	fn opAddAssign(v: f32)
	{
		x += v;
		y += v;
		z += v;
	}

	fn opSub(ref vec: Vector3f) Vector3f
	{
		return Vector3f.opCall(vec.x - x, vec.y - y, vec.z - z);
	}

	fn opSubAssign(ref vec: Vector3f)
	{
		x -= vec.x;
		y -= vec.y;
		z -= vec.z;
	}

	fn opSubAssign(v: f32)
	{
		x -= v;
		y -= v;
		z -= v;
	}

	fn opNeg() Vector3f
	{
		p: Vector3f = { -x, -y, -z };
		return p;
	}

	fn opMul(ref vec: Vector3f) Vector3f
	{
		v: Vector3f = {
			y * vec.z - z * vec.y,
			z * vec.x - x * vec.z,
			x * vec.y - y * vec.x,
		};
		return v;
	}

	fn opMul(val: f32) Vector3f
	{
		v: Vector3f = {
			x * val,
			y * val,
			z * val,
		};
		return v;
	}

	fn scale(val: f32)
	{
		x *= val;
		y *= val;
		z *= val;
	}

	fn floor()
	{
		x = .floor(x);
		y = .floor(y);
		z = .floor(z);
	}

	fn normalize()
	{
		l := length();

		if (l == 0.0) {
			return;
		}

		x /= l;
		y /= l;
		z /= l;
	}

	fn length() f32
	{
		return sqrt(lengthSqrd());
	}

	fn lengthSqrd() f32
	{
		return x * x + y * y + z * z;
	}

	fn dot(vec: Vector3f) f32
	{
		return x* vec.x + y* vec.y + z* vec.z;
	}

	fn toString() string
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}


/*!
 * Vector in a 3D space. Charge follows the OpenGL convetion for axis
 * so Y+ is up, X+ is right and Z- is forward.
 *
 * @ingroup Math
 */
struct Vector3d
{
public:
	x, y, z: f64;

	global Up: Vector3d      = { 0.0,  1.0,  0.0};
	global Forward: Vector3d = { 0.0,  0.0, -1.0};
	global Left: Vector3d =    {-1.0,  0.0,  0.0};


public:
	fn toString() string
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}
