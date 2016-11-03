// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Vector3f.
 */
module charge.math.vector;

import watt.math;
import watt.text.format;
import charge.math.point;


/**
 * Vector in a 3D space. Charge follows the OpenGL convetion for axis
 * so Y+ is up, X+ is right and Z- is forward.
 *
 * @ingroup Math
 */
struct Vector3f
{
public:
	float x, y, z;

	global const Vector3f Up =      { 0.0f, 1.0f,  0.0f};
//	global const Vector3f Heading = { 0.0f, 0.0f, -1.0f};
//	global const Vector3f Left =    {-1.0f, 0.0f,  0.0f};


public:
	global Vector3f opCall(float x, float y, float z)
	{
		Vector3f v = { x, y, z };
		return v;
	}

	global Vector3f opCall(Point3f pos)
	{
		Vector3f v = { pos.x, pos.y, pos.z };
		return v;
	}

	global Vector3f opCall(ref float[3] vec)
	{
		Vector3f v = { vec[0], vec[1], vec[2] };
		return v;
	}

	global Vector3f opCall(ref float[4] vec)
	{
		Vector3f v = { vec[0], vec[1], vec[2] };
		return v;
	}

	@property float* ptr()
	{
		return &x;
	}


	Point3f opAdd(ref Point3f vec)
	{
		return Point3f.opCall(vec.x + x, vec.y + y, vec.z + z);
	}

	Vector3f opAdd(ref Vector3f vec)
	{
		return Vector3f.opCall(vec.x + x, vec.y + y, vec.z + z);
	}

	void opAddAssign(Vector3f vec)
	{
		x += vec.x;
		y += vec.y;
		z += vec.z;
	}

	void opAddAssign(float v)
	{
		x += v;
		y += v;
		z += v;
	}

	Vector3f opSub(ref Vector3f vec)
	{
		return Vector3f.opCall(vec.x - x, vec.y - y, vec.z - z);
	}

	void opSubAssign(ref Vector3f vec)
	{
		x -= vec.x;
		y -= vec.y;
		z -= vec.z;
	}

	void opSubAssign(float v)
	{
		x -= v;
		y -= v;
		z -= v;
	}

	Vector3f opNeg()
	{
		Vector3f p = { -x, -y, -z };
		return p;
	}

	Vector3f opMul(ref Vector3f vec)
	{
		Vector3f v = {
			y * vec.z - z * vec.y,
			z * vec.x - x * vec.z,
			x * vec.y - y * vec.x,
		};
		return v;
	}

	void scale(float v)
	{
		x *= v;
		y *= v;
		z *= v;
	}

	void floor()
	{
		x = .floor(x);
		y = .floor(y);
		z = .floor(z);
	}

	void normalize()
	{
		f32 l = length();

		if (l == 0.0) {
			return;
		}

		x /= l;
		y /= l;
		z /= l;
	}

	float length()
	{
		return sqrt(lengthSqrd());
	}

	float lengthSqrd()
	{
		return x * x + y * y + z * z;
	}

	float dot(Vector3f vector)
	{
		return x*vector.x + y*vector.y + z*vector.z;
	}

	string toString()
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}
