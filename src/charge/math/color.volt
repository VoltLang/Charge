// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for colors used in graphics.
 */
module charge.math.color;

import watt.text.format;


struct Color4b
{
public:
	r, g, b, a: u8;

	global White: const(Color4b) = {255, 255, 255, 255};
	global Black: const(Color4b) = {  0,   0,   0, 255};

public:
	global fn opCall(r: u8, g: u8, b: u8, a: u8) Color4b
	{
		res: Color4b = {r, g, b, a};
		return res;
	}

	global fn opCall(value: uint) Color4b
	{
		res: Color4b = {
			cast(u8)((value >> 24) & 0xff),
			cast(u8)((value >> 16) & 0xff),
			cast(u8)((value >>  8) & 0xff),
			cast(u8)((value >>  0) & 0xff),
		};
		return res;
	}

	fn modulate(c: Color4b)
	{
		c1 := Color4f.opCall(this);
		c2 := Color4f.opCall(c);

		r = cast(u8)(c1.r * c2.r * 255);
		g = cast(u8)(c1.g * c2.g * 255);
		b = cast(u8)(c1.b * c2.b * 255);
		a = cast(u8)(c1.a * c2.a * 255);
	}

	fn blend(c: Color4b)
	{
		c1 := Color4f.opCall(this);
		c2 := Color4f.opCall(c);

		alpha := c2.a;
		alpha_minus_one := 1.0f - c2.a;

		r = cast(u8)((c1.r * alpha_minus_one + c2.r * alpha) * 255);
		g = cast(u8)((c1.g * alpha_minus_one + c2.g * alpha) * 255);
		b = cast(u8)((c1.b * alpha_minus_one + c2.b * alpha) * 255);
		a = cast(u8)((c1.a * alpha_minus_one + c2.a * alpha) * 255);
	}

	fn toString() string
	{
		return format("(%s, %s, %s, %s)", r, g, b, a);
	}
/+
	inout(u8)* ptr() @property inout { return &r; }
+/
}


struct Color3f
{
public:
	r, g, b: f32;

	global White: const(Color3f) = {1.0f, 1.0f, 1.0f};
	global Black: const(Color3f) = {0.0f, 0.0f, 0.0f};

public:
	global fn opCall(r: f32, g: f32, b: f32) Color3f
	{
		res: Color3f = {r, g, b};
		return res;
	}

	global fn opCall(c: Color4b) Color3f
	{
		return Color3f.opCall(c.r / 255.0f, c.g / 255.0f, c.b / 255.0f);
	}

	fn toString() string
	{
		return format("(%s, %s, %s)", r, g, b);
	}
/+
	inout(f32)* ptr() @property inout { return &r; }
+/
}


struct Color4f
{
public:
	r, g, b, a: f32;

	global White: const(Color4f) = {1.0f, 1.0f, 1.0f, 1.0f};
	global Black: const(Color4f) = {0.0f, 0.0f, 0.0f, 1.0f};

public:
	global fn opCall() Color4f
	{
		return Black;
	}

	global fn opCall(c: Color4b) Color4f
	{
		return Color4f.opCall(c.r / 255.0f, c.g / 255.0f, c.b / 255.0f, c.a / 255.0f);
	}

	global fn opCall(c: Color3f) Color4f
	{
		return Color4f.opCall(c.r, c.g, c.b, 1.0f);
	}

	global fn opCall(r: f32, g: f32, b: f32) Color4f
	{
		return Color4f.opCall(r, g, b, 1.0f);
	}

	global fn opCall(r: f32, g: f32, b: f32, a: f32) Color4f
	{
		res: Color4f = {r, g, b, a};
		return res;
	}

	fn toString() string
	{
		return format("(%s, %s, %s, %s)", r, g, b, a);
	}
/+
	inout(f32)* ptr() @property inout { return &r; }
+/
}
