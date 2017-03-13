// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Frustum and Plane.
 */
module charge.math.frustum;

import watt.math;
import watt.text.format;
import charge.math.matrix;


/**
 * 3D Plane uses single precision.
 *
 * @ingroup Math
 */
struct Planef
{
public:
	f32 a, b, c, d;


public:
	fn setFrom(ref p: Planed)
	{
		a = cast(f32)p.a;
		b = cast(f32)p.b;
		c = cast(f32)p.c;
		d = cast(f32)p.d;
	}

	string toString()
	{
		return format("((%s, %s, %s), %s)", a, b, c, d);
	}
}

/**
 * 3D Plane used by the Frustum struct, double precision.
 *
 * @ingroup Math
 */
struct Planed
{
public:
	f64 a, b, c, d;


public:
	fn normalize()
	{
		mag := sqrt(a * a + b * b + c * c);
		a /= mag;
		b /= mag;
		c /= mag;
		d /= mag;
	}

	fn toString() string
	{
		return format("((%s, %s, %s), %s)", a, b, c, d);
	}
}

/**
 * Viewing frustum struct for use when doing Frustum
 * culling in the rendering pipeline.
 *
 * @see http://en.wikipedia.org/wiki/Viewing_frustum
 * @see http://en.wikipedia.org/wiki/Frustum_culling
 * @ingroup Math
 */
struct Frustum
{
public:
	Planed[6] p;

	enum Planes {
		Left,
		Right,
		Top,
		Bottom,
		Far,
		Near,
	};

	alias Left   = Planes.Left;
	alias Right  = Planes.Right;
	alias Top    = Planes.Top;
	alias Bottom = Planes.Bottom;
	alias Far    = Planes.Far;
	alias Near   = Planes.Near;


public:
	fn setFromGL(ref mat: Matrix4x4d)
	{
		p[Left].a = mat.u.m[0][3] + mat.u.m[0][0];
		p[Left].b = mat.u.m[1][3] + mat.u.m[1][0];
		p[Left].c = mat.u.m[2][3] + mat.u.m[2][0];
		p[Left].d = mat.u.m[3][3] + mat.u.m[3][0];
		p[Left].normalize();

		p[Right].a = mat.u.m[0][3] - mat.u.m[0][0];
		p[Right].b = mat.u.m[1][3] - mat.u.m[1][0];
		p[Right].c = mat.u.m[2][3] - mat.u.m[2][0];
		p[Right].d = mat.u.m[3][3] - mat.u.m[3][0];
		p[Right].normalize();

		p[Top].a = mat.u.m[0][3] - mat.u.m[0][1];
		p[Top].b = mat.u.m[1][3] - mat.u.m[1][1];
		p[Top].c = mat.u.m[2][3] - mat.u.m[2][1];
		p[Top].d = mat.u.m[3][3] - mat.u.m[3][1];
		p[Top].normalize();

		p[Bottom].a = mat.u.m[0][3] + mat.u.m[0][1];
		p[Bottom].b = mat.u.m[1][3] + mat.u.m[1][1];
		p[Bottom].c = mat.u.m[2][3] + mat.u.m[2][1];
		p[Bottom].d = mat.u.m[3][3] + mat.u.m[3][1];
		p[Bottom].normalize();

		p[Far].a = mat.u.m[0][3] - mat.u.m[0][2];
		p[Far].b = mat.u.m[1][3] - mat.u.m[1][2];
		p[Far].c = mat.u.m[2][3] - mat.u.m[2][2];
		p[Far].d = mat.u.m[3][3] - mat.u.m[3][2];
		p[Far].normalize();

		p[Near].a = mat.u.m[0][3] + mat.u.m[0][2];
		p[Near].b = mat.u.m[1][3] + mat.u.m[1][2];
		p[Near].c = mat.u.m[2][3] + mat.u.m[2][2];
		p[Near].d = mat.u.m[3][3] + mat.u.m[3][2];
		p[Near].normalize();
	}
}
