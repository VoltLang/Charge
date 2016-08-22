// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.viewer;

import watt.math;
import watt.io.file;
import watt.algorithm;
import io = watt.io;

import charge.ctl;
import charge.sys.memory;
import charge.sys.resource;
import charge.core;
import charge.game;
import charge.gfx;

import math = charge.math;

import power.voxel;


class Viewer : GameSimpleScene
{
public:
	CtlInput input;
	VoxelBuffer vbo;
	float rotation;
	GfxFramebuffer fbo;
	GfxDrawBuffer quad;
	GfxShader voxelShader;
	GfxShader aaShader;
	GLuint sampler;


public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		input = CtlInput.opCall();
		vbo = doit();

		voxelShader = new GfxShader(voxelVertexES, voxelFragmentES,
		                            ["position", "color"], null);
		aaShader = new GfxShader(aaVertex130, aaFragment130,
		                         ["position"], ["color", "depth"]);


		auto b = new GfxDrawVertexBuilder(4);
		b.add(-1.f, -1.f, -1.f, -1.f);
		b.add( 1.f, -1.f,  1.f, -1.f);
		b.add( 1.f,  1.f,  1.f,  1.f);
		b.add(-1.f,  1.f, -1.f,  1.f);
		quad = GfxDrawBuffer.make("power/quad", b);

		glGenSamplers(1, &sampler);
		glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}

	override void close()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (quad !is null) { quad.decRef(); quad = null; }
		if (sampler) { glDeleteSamplers(1, &sampler); sampler = 0; }
		if (voxelShader !is null) {
			voxelShader.breakApart();
			voxelShader = null;
		}
		if (aaShader !is null) {
			aaShader.breakApart();
			aaShader = null;
		}
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void logic()
	{
		rotation += 0.01f;
	}

	override void render(GfxTarget t)
	{
		// If there is none or if t has a different size.
		setupFramebuffer(t);

		// Use the fbo
		t.unbind();
		fbo.bind();
		renderScene(fbo);
		fbo.unbind();
		t.bind();


		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		aaShader.bind();

		glBindVertexArray(quad.vao);

		fbo.color.bind();
		glBindSampler(0, sampler);

		glDrawArrays(GL_QUADS, 0, quad.num);

		glBindSampler(0, 0);
		fbo.color.unbind();

		glBindVertexArray(0);
	}

	override void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
	}

	void setupFramebuffer(GfxTarget t)
	{
		if (fbo !is null &&
		    (t.width * 2) == fbo.width &&
		    (t.height * 2) == fbo.height) {
			return;
		}

		if (fbo !is null) { fbo.decRef(); fbo = null; }
		fbo = GfxFramebuffer.make("power/fbo", t.width * 2, t.height * 2);
	}

	void renderScene(GfxTarget t)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);


		rot := math.Quatf.opCall(rotation, 0.f, 0.f);
		vec := rot * math.Vector3f.opCall(0.f, 0.f, -32.f);
		pos := math.Point3f.opCall(16.f, 8.f, 16.f) - vec;


		math.Matrix4x4f view;
		view.setToLookFrom(ref pos, ref rot);

		math.Matrix4x4f proj;
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 256.f);
		proj.setToMultiply(ref view);


		// Setup shader.
		voxelShader.bind();
		voxelShader.matrix4("matrix", 1, true, proj.ptr);

		// Setup shader.
		glBindVertexArray(vbo.vao);
		glDrawArrays(GL_QUADS, 0, vbo.num);
		glBindVertexArray(0);

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);
	}
}

/**
 * VBO used for Voxels.
 */
class VoxelBuffer : GfxBuffer
{
public:
	GLsizei num;


public:
	global VoxelBuffer make(string name, VoxelBuilder vb)
	{
		void* dummy;
		auto buffer = cast(VoxelBuffer)Resource.alloc(
			typeid(VoxelBuffer), uri, name, 0, out dummy);
		buffer.__ctor(0, 0);
		buffer.update(vb);
		return buffer;
	}

	void update(VoxelBuilder vb)
	{
		deleteBuffers();
		vb.bake(out vao, out buf, out num);
	}


protected:
	this(GLuint vao, GLuint buf)
	{
		super(vao, buf);
	}
}


@mangledName("llvm.ctpop.i64") u64 bitcount(u64);

struct Header
{
	char[4] magic;
	u32 ver;
}

struct Chunk
{
	char[4] id;
	u32 chunkSize;
	u32 childSize;
}

struct Voxel
{
	u8 x;
	u8 y;
	u8 z;
	u8 c;
}

VoxelBuffer doit()
{
	arr := cast(ubyte[])read("res/test.vox");
	ptr := cast(ubyte*)arr.ptr;
	end := cast(ubyte*)arr.ptr + arr.length;
	h := *cast(Header*)ptr; ptr += typeid(Header).size;

	x, y, z : u32;
	bitArray : u64[];
	voxels : Voxel[];
	numVoxels : size_t;
	colors := defaultColors;

	void setBit(Voxel v) {
		i := encodeVoxel(v);
		index := i / 64;
		bit := 1UL << (i % 64UL);
		bitArray[index] |= bit;
	}

	while (cast(size_t)ptr < cast(size_t)end) {
		c := cast(Chunk*)ptr; ptr += typeid(Chunk).size;

		switch (c.id[..]) {
		case "MAIN": break;
		case "SIZE":
			u32Ptr := cast(u32*)ptr;
			x = u32Ptr[0];
			y = u32Ptr[1];
			z = u32Ptr[2];
			max := (math.encode(x, y, z) / 64) + 1;
			bitArray = new u64[](max);
			break;
		case "XYZI":
			numVoxels = *cast(u32*)ptr;
			voxels = (cast(Voxel*)(ptr + 4))[0 .. numVoxels];
			sortVoxels(voxels);
			foreach (v; voxels) {
				setBit(v);
			}
			break;
		case "RGBA":
			colors = (cast(math.Color4b*)ptr)[0 .. 256];
			break;
		default:
		}
		ptr = ptr + c.chunkSize;
	}

	vb := new VoxelBuilder(numVoxels);

	bool isSet(u32 x, u32 y, u32 z) {
		return false;
	}

	// Loop trough voxels in morton order.
	voxelPos : size_t;
	foreach (block; bitArray) {
		foreach (shift; 0UL .. 64UL) {
			bit := 1UL << shift;

			if (!(bit & block)) {
				continue;
			}

			v := voxels[voxelPos++];
			color := colors[v.c-1];
			vb.addCube(cast(f32)v.x, cast(f32)v.z, cast(f32)v.y, color);
		}
	}

	return VoxelBuffer.make("voxels", vb);
}

private u64 encodeVoxel(Voxel a)
{
	return math.encode(a.x, a.z, a.y);
}

private void sortVoxels(Voxel[] voxels)
{
	bool cmp(size_t a, size_t b)
	{
		return encodeVoxel(voxels[a]) < encodeVoxel(voxels[b]);
	}

	void swap(size_t a, size_t b)
	{
		t := voxels[a];
		voxels[a] = voxels[b];
		voxels[b] = t;
	}

	runSort(voxels.length, cmp, swap);
}

global math.Color4b[] defaultColors = [
	{255, 255, 255, 255}, {255, 255, 204, 255}, {255, 255, 153, 255},
	{255, 255, 102, 255}, {255, 255,  51, 255}, {255, 255,   0, 255},
	{255, 204, 255, 255}, {255, 204, 204, 255}, {255, 204, 153, 255},
	{255, 204, 102, 255}, {255, 204,  51, 255}, {255, 204,   0, 255},
	{255, 153, 255, 255}, {255, 153, 204, 255}, {255, 153, 153, 255},
	{255, 153, 102, 255}, {255, 153,  51, 255}, {255, 153,   0, 255},
	{255, 102, 255, 255}, {255, 102, 204, 255}, {255, 102, 153, 255},
	{255, 102, 102, 255}, {255, 102,  51, 255}, {255, 102,   0, 255},
	{255,  51, 255, 255}, {255,  51, 204, 255}, {255,  51, 153, 255},
	{255,  51, 102, 255}, {255,  51,  51, 255}, {255,  51,   0, 255},
	{255,   0, 255, 255}, {255,   0, 204, 255}, {255,   0, 153, 255},
	{255,   0, 102, 255}, {255,   0,  51, 255}, {255,   0,   0, 255},
	{204, 255, 255, 255}, {204, 255, 204, 255}, {204, 255, 153, 255},
	{204, 255, 102, 255}, {204, 255,  51, 255}, {204, 255,   0, 255},
	{204, 204, 255, 255}, {204, 204, 204, 255}, {204, 204, 153, 255},
	{204, 204, 102, 255}, {204, 204,  51, 255}, {204, 204,   0, 255},
	{204, 153, 255, 255}, {204, 153, 204, 255}, {204, 153, 153, 255},
	{204, 153, 102, 255}, {204, 153,  51, 255}, {204, 153,   0, 255},
	{204, 102, 255, 255}, {204, 102, 204, 255}, {204, 102, 153, 255},
	{204, 102, 102, 255}, {204, 102,  51, 255}, {204, 102,   0, 255},
	{204,  51, 255, 255}, {204,  51, 204, 255}, {204,  51, 153, 255},
	{204,  51, 102, 255}, {204,  51,  51, 255}, {204,  51,   0, 255},
	{204,   0, 255, 255}, {204,   0, 204, 255}, {204,   0, 153, 255},
	{204,   0, 102, 255}, {204,   0,  51, 255}, {204,   0,   0, 255},
	{153, 255, 255, 255}, {153, 255, 204, 255}, {153, 255, 153, 255},
	{153, 255, 102, 255}, {153, 255,  51, 255}, {153, 255,   0, 255},
	{153, 204, 255, 255}, {153, 204, 204, 255}, {153, 204, 153, 255},
	{153, 204, 102, 255}, {153, 204,  51, 255}, {153, 204,   0, 255},
	{153, 153, 255, 255}, {153, 153, 204, 255}, {153, 153, 153, 255},
	{153, 153, 102, 255}, {153, 153,  51, 255}, {153, 153,   0, 255},
	{153, 102, 255, 255}, {153, 102, 204, 255}, {153, 102, 153, 255},
	{153, 102, 102, 255}, {153, 102,  51, 255}, {153, 102,   0, 255},
	{153,  51, 255, 255}, {153,  51, 204, 255}, {153,  51, 153, 255},
	{153,  51, 102, 255}, {153,  51,  51, 255}, {153,  51,   0, 255},
	{153,   0, 255, 255}, {153,   0, 204, 255}, {153,   0, 153, 255},
	{153,   0, 102, 255}, {153,   0,  51, 255}, {153,   0,   0, 255},
	{102, 255, 255, 255}, {102, 255, 204, 255}, {102, 255, 153, 255},
	{102, 255, 102, 255}, {102, 255,  51, 255}, {102, 255,   0, 255},
	{102, 204, 255, 255}, {102, 204, 204, 255}, {102, 204, 153, 255},
	{102, 204, 102, 255}, {102, 204,  51, 255}, {102, 204,   0, 255},
	{102, 153, 255, 255}, {102, 153, 204, 255}, {102, 153, 153, 255},
	{102, 153, 102, 255}, {102, 153,  51, 255}, {102, 153,   0, 255},
	{102, 102, 255, 255}, {102, 102, 204, 255}, {102, 102, 153, 255},
	{102, 102, 102, 255}, {102, 102,  51, 255}, {102, 102,   0, 255},
	{102,  51, 255, 255}, {102,  51, 204, 255}, {102,  51, 153, 255},
	{102,  51, 102, 255}, {102,  51,  51, 255}, {102,  51,   0, 255},
	{102,   0, 255, 255}, {102,   0, 204, 255}, {102,   0, 153, 255},
	{102,   0, 102, 255}, {102,   0,  51, 255}, {102,   0,   0, 255},
	{ 51, 255, 255, 255}, { 51, 255, 204, 255}, { 51, 255, 153, 255},
	{ 51, 255, 102, 255}, { 51, 255,  51, 255}, { 51, 255,   0, 255},
	{ 51, 204, 255, 255}, { 51, 204, 204, 255}, { 51, 204, 153, 255},
	{ 51, 204, 102, 255}, { 51, 204,  51, 255}, { 51, 204,   0, 255},
	{ 51, 153, 255, 255}, { 51, 153, 204, 255}, { 51, 153, 153, 255},
	{ 51, 153, 102, 255}, { 51, 153,  51, 255}, { 51, 153,   0, 255},
	{ 51, 102, 255, 255}, { 51, 102, 204, 255}, { 51, 102, 153, 255},
	{ 51, 102, 102, 255}, { 51, 102,  51, 255}, { 51, 102,   0, 255},
	{ 51,  51, 255, 255}, { 51,  51, 204, 255}, { 51,  51, 153, 255},
	{ 51,  51, 102, 255}, { 51,  51,  51, 255}, { 51,  51,   0, 255},
	{ 51,   0, 255, 255}, { 51,   0, 204, 255}, { 51,   0, 153, 255},
	{ 51,   0, 102, 255}, { 51,   0,  51, 255}, { 51,   0,   0, 255},
	{  0, 255, 255, 255}, {  0, 255, 204, 255}, {  0, 255, 153, 255},
	{  0, 255, 102, 255}, {  0, 255,  51, 255}, {  0, 255,   0, 255},
	{  0, 204, 255, 255}, {  0, 204, 204, 255}, {  0, 204, 153, 255},
	{  0, 204, 102, 255}, {  0, 204,  51, 255}, {  0, 204,   0, 255},
	{  0, 153, 255, 255}, {  0, 153, 204, 255}, {  0, 153, 153, 255},
	{  0, 153, 102, 255}, {  0, 153,  51, 255}, {  0, 153,   0, 255},
	{  0, 102, 255, 255}, {  0, 102, 204, 255}, {  0, 102, 153, 255},
	{  0, 102, 102, 255}, {  0, 102,  51, 255}, {  0, 102,   0, 255},
	{  0,  51, 255, 255}, {  0,  51, 204, 255}, {  0,  51, 153, 255},
	{  0,  51, 102, 255}, {  0,  51,  51, 255}, {  0,  51,   0, 255},
	{  0,   0, 255, 255}, {  0,   0, 204, 255}, {  0,   0, 153, 255},
	{  0,   0, 102, 255}, {  0,   0,  51, 255}, {238,   0,   0, 255},
	{221,   0,   0, 255}, {187,   0,   0, 255}, {170,   0,   0, 255},
	{136,   0,   0, 255}, {119,   0,   0, 255}, { 85,   0,   0, 255},
	{ 68,   0,   0, 255}, { 34,   0,   0, 255}, { 17,   0,   0, 255},
	{  0, 238,   0, 255}, {  0, 221,   0, 255}, {  0, 187,   0, 255},
	{  0, 170,   0, 255}, {  0, 136,   0, 255}, {  0, 119,   0, 255},
	{  0,  85,   0, 255}, {  0,  68,   0, 255}, {  0,  34,   0, 255},
	{  0,  17,   0, 255}, {  0,   0, 238, 255}, {  0,   0, 221, 255},
	{  0,   0, 187, 255}, {  0,   0, 170, 255}, {  0,   0, 136, 255},
	{  0,   0, 119, 255}, {  0,   0,  85, 255}, {  0,   0,  68, 255},
	{  0,   0,  34, 255}, {  0,   0,  17, 255}, {238, 238, 238, 255},
	{221, 221, 221, 255}, {187, 187, 187, 255}, {170, 170, 170, 255},
	{136, 136, 136, 255}, {119, 119, 119, 255}, { 85,  85,  85, 255},
	{ 68,  68,  68, 255}, { 34,  34,  34, 255}, { 17,  17,  17, 255}
];

enum string voxelVertexES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute vec3 position;
attribute vec4 color;

uniform mat4 matrix;

varying vec4 colorFs;

void main(void)
{
	colorFs = color;
	gl_Position = matrix * vec4(position, 1.0);
}
`;

enum string voxelFragmentES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

varying vec4 colorFs;

void main(void)
{
	gl_FragColor = colorFs;
}
`;

enum string aaVertex130 = `
#version 130
#extension GL_ARB_gpu_shader5 : require

attribute vec2 position;

varying vec2 uvFS;

void main(void)
{
	uvFS = (position / 2 + 0.5);
	uvFS.y = 1 - uvFS.y;
	gl_Position = vec4(position, 0.0, 1.0);
}
`;

enum string aaFragment130 = `
#version 130
#extension GL_ARB_gpu_shader5 : require

uniform sampler2D color;

varying vec2 uvFS;

float doTest(vec4 a)
{
	return float(any(notEqual(a, a.yzwx)));
}

void main(void)
{
	// Get color.
	vec4 c = texture(color, uvFS);

	vec4 s1 = textureGatherOffset(color, uvFS, ivec2(0,  1), 3);
	vec4 s2 = textureGatherOffset(color, uvFS, ivec2(0, -1), 3);
	vec4 s3 = textureGatherOffset(color, uvFS, ivec2( 1, 0), 3);
	vec4 s4 = textureGatherOffset(color, uvFS, ivec2(-1, 0), 3);

	// textureGather(color, uvFS, 3);
	vec4 a = vec4(s1.wz, s2.yx);

	float factor = doTest(a) * .4 +
		doTest(s1) * .3 +
		doTest(s2) * .3 +
		doTest(s3) * .3 +
		doTest(s4) * .3;

	gl_FragColor = mix(c, vec4(0, 0, 0, 1), factor);
}
`;
