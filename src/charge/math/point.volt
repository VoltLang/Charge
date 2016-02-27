// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Point3f.
 */
module charge.math.point;

import watt.text.format;
import charge.math.vector;


/**
 * Point in 3D space.
 *
 * @ingroup Math
 */
struct Point3f
{
public:
	float x, y, z;

public:
	static Point3f opCall()
	{
		Point3f p = { 0.0f, 0.0f, 0.0f };
		return p;
	}

	static Point3f opCall(float x, float y, float z)
	{
		Point3f p = { x, y, z };
		return p;
	}

	static Point3f opCall(Vector3f vec)
	{
		Point3f p = { vec.x, vec.y, vec.z };
		return p;
	}

	static Point3f opCall(float[3] vec)
	{
		Point3f p = { vec[0], vec[1], vec[2] };
		return p;
	}

	static Point3f opCall(float[4] vec)
	{
		Point3f p = { vec[0], vec[1], vec[2] };
		return p;
	}

/+
	double opIndex(uint index) const
	{
		return (&x)[index];
	}
+/

	Point3f opAdd(Vector3f vec)
	{
		return Point3f.opCall(x + vec.x, y + vec.y, z + vec.z);
	}

	Point3f opAddAssign(Vector3f v)
	{
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}

	Vector3f opSub(Point3f p)
	{
		return Vector3f.opCall(x - p.x, y - p.y, z - p.z);
	}

	Point3f opSub(Vector3f v)
	{
		return Point3f.opCall(x - v.x, y - v.y, z - v.z);
	}

	Point3f opNeg()
	{
		return Point3f.opCall(-x, -y, -z);
	}

	Point3f opSubAssign(Vector3f v)
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

	Vector3f vec()
	{
		return Vector3f.opCall(this);
	}

	string toString()
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}
