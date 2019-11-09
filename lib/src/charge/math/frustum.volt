// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Frustum and Plane.
 *
 * @ingroup math
 */
module charge.math.frustum;

import watt.math;
import watt.text.format;
import charge.math.matrix;


/*!
 * 3D Plane uses single precision.
 *
 * @ingroup math
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

/*!
 * 3D Plane used by the Frustum struct, double precision.
 *
 * @ingroup math
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

/*!
 * Viewing frustum struct for use when doing Frustum
 * culling in the rendering pipeline.
 *
 * @see http://en.wikipedia.org/wiki/Viewing_frustum
 * @see http://en.wikipedia.org/wiki/Frustum_culling
 * @ingroup math
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
	fn setFromUntransposedGL(ref mat: Matrix4x4d)
	{
		p[Left].a = mat.u.m[3][0] + mat.u.m[0][0];
		p[Left].b = mat.u.m[3][1] + mat.u.m[0][1];
		p[Left].c = mat.u.m[3][2] + mat.u.m[0][2];
		p[Left].d = mat.u.m[3][3] + mat.u.m[0][3];
		p[Left].normalize();

		p[Right].a = mat.u.m[3][0] - mat.u.m[0][0];
		p[Right].b = mat.u.m[3][1] - mat.u.m[0][1];
		p[Right].c = mat.u.m[3][2] - mat.u.m[0][2];
		p[Right].d = mat.u.m[3][3] - mat.u.m[0][3];
		p[Right].normalize();

		p[Top].a = mat.u.m[3][0] - mat.u.m[1][0];
		p[Top].b = mat.u.m[3][1] - mat.u.m[1][1];
		p[Top].c = mat.u.m[3][2] - mat.u.m[1][2];
		p[Top].d = mat.u.m[3][3] - mat.u.m[1][3];
		p[Top].normalize();

		p[Bottom].a = mat.u.m[3][0] + mat.u.m[1][0];
		p[Bottom].b = mat.u.m[3][1] + mat.u.m[1][1];
		p[Bottom].c = mat.u.m[3][2] + mat.u.m[1][2];
		p[Bottom].d = mat.u.m[3][3] + mat.u.m[1][3];
		p[Bottom].normalize();

		p[Far].a = mat.u.m[3][0] - mat.u.m[2][0];
		p[Far].b = mat.u.m[3][1] - mat.u.m[2][1];
		p[Far].c = mat.u.m[3][2] - mat.u.m[2][2];
		p[Far].d = mat.u.m[3][3] - mat.u.m[2][3];
		p[Far].normalize();

		p[Near].a = mat.u.m[3][0] + mat.u.m[2][0];
		p[Near].b = mat.u.m[3][1] + mat.u.m[2][1];
		p[Near].c = mat.u.m[3][2] + mat.u.m[2][2];
		p[Near].d = mat.u.m[3][3] + mat.u.m[2][3];
		p[Near].normalize();
	}
}
