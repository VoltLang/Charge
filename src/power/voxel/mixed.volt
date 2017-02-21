// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.voxel.mixed;

import watt.text.string;
import watt.text.format;
import watt.io.file;

import charge.gfx;
import charge.sys.resource;

import math = charge.math;

import power.util.counters;
import power.voxel.dag;
import power.voxel.boxel;
import power.voxel.instance;


fn calcAlign(pos: i32, level: i32) i32
{
	shift := level + 1;
	size := 1 << level;
	return ((pos + size) >> shift) << shift;
}

fn getAlignedPosition(ref camPosition: math.Point3f,
                      out position: math.Vector3f,
                      scaleFactor: f32)
{
	position = math.Vector3f.opCall(camPosition);
	position.scale(scaleFactor);
	position.floor();

	vec := math.Vector3f.opCall(
		cast(f32)calcAlign(cast(i32)position.x, 0),
		cast(f32)calcAlign(cast(i32)position.y, 0),
		cast(f32)calcAlign(cast(i32)position.z, 0));
}
	
fn calcNumMorton(dim: i32) i32
{
	return dim * dim * dim;
}


class Mixed
{
public:
	counters: Counters;


protected:
	mTrace: GfxShader;

	/// The number of levels that we trace.
	mTracePower: i32;
	mTracePowerStr: string;

	mOctTexture: GLuint;
	mFeedbackQuery: GLuint;


public:
	this(octTexture: GLuint)
	{
		counters = new Counters("trace");

		mTracePower = 2;
		mTracePowerStr = format("#define TRACE_POWER %s", mTracePower);

		mOctTexture = octTexture;
		glGenQueries(1, &mFeedbackQuery);

		vert, geom, frag: string;

		vert = cast(string)read("res/power/shaders/mixed/trace.vert.glsl");
		frag = cast(string)read("res/power/shaders/mixed/trace.frag.glsl");
		mTrace = makeShaderVGF("mixed.trace", vert, null, frag);
	}

	void close()
	{
		if (counters !is null) {
			counters.close();
			counters = null;
		}
		if (mTrace !is null) {
			mTrace.breakApart();
			mTrace = null;
		}
	}

	fn draw(ref camPosition: math.Point3f, ref mat: math.Matrix4x4f)
	{
		glCheckError();

		counters.start(0);
		counters.stop(0);
	}



private:
	fn makeShaderVGF(name: string, vert: string, geom: string, frag: string) GfxShader
	{
		vert = replaceShaderStrings(vert);
		geom = replaceShaderStrings(geom);
		frag = replaceShaderStrings(frag);
		return new GfxShader(name, vert, geom, frag);
	}

	fn replaceShaderStrings(shader: string) string
	{
		shader = replace(shader, "#define TRACE_POWER %%",   mTracePowerStr);
		return shader;
	}
}
