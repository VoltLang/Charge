// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for colors used in graphics.
 */
module charge.math.color;

import watt.text.format;


/*!
 * A color value with 8 bits of unsigned values per channel.
 *
 * Is layed out in memory in r, g, b, a order. For little endian machines this
 * means that reading the color as a u32 it will return it in ABGR form.
 */
struct Color4b
{
public:
	r, g, b, a: u8;

	global White: const(Color4b) = {255, 255, 255, 255};
	global Black: const(Color4b) = {  0,   0,   0, 255};


public:
	global fn from(rf: f32, gf: f32, bf: f32, af: f32) Color4b
	{
		cf := Color4f.from(rf, gf, bf, af);

		return from(cast(u8)(cf.r * 255.0f),
		            cast(u8)(cf.g * 255.0f),
		            cast(u8)(cf.b * 255.0f),
		            cast(u8)(cf.a * 255.0f));
	}

	global fn from(r: u8, g: u8, b: u8, a: u8) Color4b
	{
		res: Color4b = {r, g, b, a};
		return res;
	}

	//! Converts a little endian RGBA value to little endian ABGR.
	global fn fromRGBA(value: u32) Color4b
	{
		// Little endian RGBA value.
		res: Color4b = {
			cast(u8)((value >> 24) & 0xff),
			cast(u8)((value >> 16) & 0xff),
			cast(u8)((value >>  8) & 0xff),
			cast(u8)((value >>  0) & 0xff),
		};
		return res;
	}

	//! Read a little endian ABGR.
	global fn fromABGR(value: u32) Color4b
	{
		// Little endian RGBA value.
		return *cast(Color4b*)&value;
	}

	fn modulate(c: Color4b)
	{
		c1 := Color4f.from(this);
		c2 := Color4f.from(c);

		r = cast(u8)(c1.r * c2.r * 255);
		g = cast(u8)(c1.g * c2.g * 255);
		b = cast(u8)(c1.b * c2.b * 255);
		a = cast(u8)(c1.a * c2.a * 255);
	}

	fn blend(c: Color4b)
	{
		c1 := Color4f.from(this);
		c2 := Color4f.from(c);

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

	fn toABGR() u32
	{
		return *cast(u32*)&this;
	}

	fn toRGBA() u32
	{
		return (cast(u32)r << 24u) |
		       (cast(u32)g << 16u) |
		       (cast(u32)b <<  8u) |
		       (cast(u32)a <<  0u);
	}

	fn opEquals(other: Color4b) bool
	{
		return other.toABGR() == this.toABGR();
	}
}


struct Color3f
{
public:
	r, g, b: f32;

	global White: const(Color3f) = {1.0f, 1.0f, 1.0f};
	global Black: const(Color3f) = {0.0f, 0.0f, 0.0f};


public:
	global fn from(r: f32, g: f32, b: f32) Color3f
	{
		res: Color3f = {r, g, b};
		return res;
	}

	global fn from(c: Color4b) Color3f
	{
		return Color3f.from(c.r / 255.0f, c.g / 255.0f, c.b / 255.0f);
	}

	fn toString() string
	{
		return format("(%s, %s, %s)", r, g, b);
	}

	@property fn ptr() f32*
	{
		return &r;
	}
}


struct Color4f
{
public:
	r, g, b, a: f32;

	global White: const(Color4f) = {1.0f, 1.0f, 1.0f, 1.0f};
	global Black: const(Color4f) = {0.0f, 0.0f, 0.0f, 1.0f};


public:
	global fn from(c: Color4b) Color4f
	{
		return Color4f.from(c.r / 255.0f, c.g / 255.0f, c.b / 255.0f, c.a / 255.0f);
	}

	global fn from(c: Color3f) Color4f
	{
		return Color4f.from(c.r, c.g, c.b, 1.0f);
	}

	global fn from(r: f32, g: f32, b: f32) Color4f
	{
		return Color4f.from(r, g, b, 1.0f);
	}

	global fn from(r: f32, g: f32, b: f32, a: f32) Color4f
	{
		res: Color4f = {r, g, b, a};
		return res;
	}

	fn opAddAssign(c: Color4b)
	{
		r += c.r * (1.0f / 255.0f);
		g += c.g * (1.0f / 255.0f);
		b += c.b * (1.0f / 255.0f);
		a += c.a * (1.0f / 255.0f);
	}

	fn opMulAssign(f: f32)
	{
		r *= f;
		g *= f;
		b *= f;
		a *= f;
	}

	fn toString() string
	{
		return format("(%s, %s, %s, %s)", r, g, b, a);
	}

	fn toABGR() u32
	{
		return ((cast(u32)(r * 255.0f) & 0xff) <<  0u) |
		       ((cast(u32)(g * 255.0f) & 0xff) <<  8u) |
		       ((cast(u32)(b * 255.0f) & 0xff) << 16u) |
		       ((cast(u32)(a * 255.0f) & 0xff) << 24u);
	}

	fn toRGBA() u32
	{
		return ((cast(u32)(r * 255.0f) & 0xff) << 24u) |
		       ((cast(u32)(g * 255.0f) & 0xff) << 16u) |
		       ((cast(u32)(b * 255.0f) & 0xff) <<  8u) |
		       ((cast(u32)(a * 255.0f) & 0xff) <<  0u);
	}

	@property fn ptr() f32*
	{
		return &r;
	}
}
