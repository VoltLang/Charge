// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.shaders;

import io = watt.io;

import watt.text.string;
import watt.text.format;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.shaders;




private global voxelShaderStoreStore: ShaderStore[const(u32)[]];

fn getStore(ref c: Create) ShaderStore
{
	key := [cast(u32)c.isAMD];
	s := key in voxelShaderStoreStore;
	if (s !is null) {
		return *s;
	}

	store := new ShaderStore(c.isAMD);
	voxelShaderStoreStore[key] = store;
	return store;
}

/*!
 * Cache shaders so they can be resude between different passes and models.
 */
class ShaderStore
{
protected:
	mShaderStore: gfx.Shader[string];
	mCompiler: gfx.Compiler;
	mIsAMD: bool;


public:
	this(isAMD: bool)
	{
		this.mIsAMD = isAMD;
		this.mCompiler = new gfx.Compiler();

		src := cast(string)import("voxel/data.glsl");
		d: gfx.Src;
		d.setup(src: src, filename: "res/voxel/data.glsl", add: true);

		mCompiler.addInclude(ref d, "voxel/data.glsl");
	}

	fn makeElementsDispatchShader(src: u32, dst: u32) gfx.Shader
	{
		name := format("svo.dispatch-elements (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/indirect-elements.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%INDIRECT_SRC%", format("%s", src));
		comp = replace(comp, "%INDIRECT_DST%", format("%s", dst));

		cc: gfx.CompSrc;
		cc.setup(src: comp, filename: "res/voxel/indirect-elements.comp.glsl", add: true);

		s := mCompiler.compile(ref cc, name);
		mShaderStore[name] = s;
		return s;
	}

	fn makeWalkFrustumShader(srcBaseIndex: u32, dstBaseIndex: u32, counterIndex: u32, powerStart: u32, powerLevels: u32) gfx.Shader
	{
		name := format("svo.walk-frustum (srcBaseIndex: %s, dstBaseIndex: %s, counterIndex: %s, powerStart: %s, powerLevels: %s)",
			srcBaseIndex, dstBaseIndex, counterIndex, powerStart, powerLevels);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/walk-frustum.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%SRC_BASE_INDEX%", format("%s", srcBaseIndex));
		comp = replace(comp, "%DST_BASE_INDEX%", format("%s", dstBaseIndex));
		comp = replace(comp, "%COUNTER_INDEX%", format("%s", counterIndex));

		comp = replace(comp, "%POWER_START%", format("%s", powerStart));
		comp = replace(comp, "%POWER_LEVELS%", format("%s", powerLevels));

		cc: gfx.CompSrc;
		cc.setup(src: comp, filename: "res/voxel/walk-frustum.comp.glsl", add: true);

		s := mCompiler.compile(ref cc, name);
		mShaderStore[name] = s;
		return s;
	}

	fn makeWalkSplitShader(srcBaseIndex: u32, dstBaseIndex: u32, counterIndex: u32, splitIndex: u32, splitSize: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.walk-split (srcBaseIndex: %s, dstBaseIndex: %s, counterIndex: %s, splitIndex: %s, splitSize: %s, powerStart: %s)",
			srcBaseIndex, dstBaseIndex, counterIndex, splitIndex, splitSize, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/walk-split.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%SRC_BASE_INDEX%", format("%s", srcBaseIndex));
		comp = replace(comp, "%DST_BASE_INDEX%", format("%s", dstBaseIndex));
		comp = replace(comp, "%COUNTER_INDEX%", format("%s", counterIndex));

		comp = replace(comp, "%SPLIT_INDEX%", format("%s", splitIndex));
		comp = replace(comp, "%SPLIT_SIZE%", format("%s", splitSize));

		comp = replace(comp, "%POWER_START%", format("%s", powerStart));


		cc: gfx.CompSrc;
		cc.setup(src: comp, filename: "res/voxel/walk-split.comp.glsl", add: true);

		s := mCompiler.compile(ref cc, name);
		mShaderStore[name] = s;
		return s;
	}

	fn makeWalkSortShader(srcBaseIndex: u32, counterIndex: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.walk-sort (srcBaseIndex: %s, counterIndex: %s, powerStart: %s)",
			srcBaseIndex, counterIndex, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/walk-sort.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%SRC_BASE_INDEX%", format("%s", srcBaseIndex));
		comp = replace(comp, "%COUNTER_INDEX%", format("%s", counterIndex));
		comp = replace(comp, "%POWER_START%", format("%s", powerStart));


		cc: gfx.CompSrc;
		cc.setup(src: comp, filename: "res/voxel/walk-sort.comp.glsl", add: true);

		s := mCompiler.compile(ref cc, name);
		mShaderStore[name] = s;
		return s;
	}

	fn makeWalkDoubleShader(counterIndex: u32) gfx.Shader
	{
		name := format("svo.walk-double (counterIndex: %s)",
			counterIndex);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/walk-double.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%COUNTER_INDEX%", format("%s", counterIndex));

		cc: gfx.CompSrc;
		cc.setup(src: comp, filename: "res/voxel/walk-double.comp.glsl", add: true);

		s := mCompiler.compile(ref cc, name);
		mShaderStore[name] = s;
		return s;
	}

	fn makePointsWalkShader(powerStart: u32) gfx.Shader
	{
		name := format("svo.points-walk (powerStart: %s)", powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/points-walk.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));
		frag := cast(string)import("voxel/points.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));

		vc: gfx.VertSrc;
		vc.setup(src: vert, filename: "res/voxel/points-walk.vert.glsl", add: true);
		fc: gfx.FragSrc;
		fc.setup(src: frag, filename: "res/voxel/points.frag.glsl", add: true);

		s := mCompiler.compile(ref vc, ref fc, name);
		mShaderStore[name] = s;
		return s;
	}

	fn makeCubesWalkShader(src: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.cube-walk (src: %s, start: %s)",
			src, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/cube-walk.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%VOXEL_SRC%", format("%s", src));
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));
		vert = replace(vert, "%POWER_LEVELS%", "0");
		frag := cast(string)import("voxel/cube-ray.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%VOXEL_SRC%", format("%s", src));
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));
		frag = replace(frag, "%POWER_LEVELS%", "0");

		vc: gfx.VertSrc;
		vc.setup(src: vert, filename: "res/voxel/cube-walk.vert.glsl", add: true);
		fc: gfx.FragSrc;
		fc.setup(src: frag, filename: "res/voxel/cube-ray.frag.glsl", add: true);

		s := mCompiler.compile(ref vc, ref fc, name);
		mShaderStore[name] = s;
		return s;
	}


private:
	fn replaceCommon(str: string) string
	{
		str = replace(str, "%RENDERER_AMD%", mIsAMD ? "1" : "0");
		str = replace(str, "%X_SHIFT%", format("%s", XShift));
		str = replace(str, "%Y_SHIFT%", format("%s", YShift));
		str = replace(str, "%Z_SHIFT%", format("%s", ZShift));
		return str;
	}
}
