// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.raytracer;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;
import io = watt.io;

import charge.ctl;
import charge.gfx;
import charge.core;
import charge.game;
import charge.sys.memory;
import charge.sys.resource;

import math = charge.math;

import power.voxel.boxel;
import power.voxel.dag;
import power.experiments.viewer;

void loadDag(string filename, out void[] data)
{
	// Setup raytracing code.
	data = read(filename);
	f32ptr := cast(f32*)data.ptr;
	u32ptr := cast(u32*)data.ptr;
	u64ptr := cast(u64*)data.ptr;

	id := u64ptr[0];
	frames := u64ptr[1];
	resolution := u64ptr[2];
	dataSizeInU32 := u64ptr[3];
	minX := f32ptr[ 8];
	minY := f32ptr[ 9];
	minZ := f32ptr[10];
	maxX := f32ptr[11];
	maxY := f32ptr[12];
	maxZ := f32ptr[13];

	// Calculate offset to data, both values are orignally in u32s.
	offset := (frames + 14UL) * 4;
	data = data[offset .. offset + dataSizeInU32 * 4];

/*
	io.writefln("id:         %016x", id);
	io.writefln("frames:     %s", frames);
	io.writefln("resolution: %s", resolution);
	io.writefln("ndwords:    %s", dataSizeInU32);
	io.writefln("rootMin:    %s %s %s", cast(f64)minX, cast(f64)minY, cast(f64)minZ);
	io.writefln("rootMax:    %s %s %s", cast(f64)maxX, cast(f64)maxY, cast(f64)maxZ);

	io.writefln("%s %s", dataSizeInU32 * 4, data.length);
	foreach (i; 0U .. 128U) {
		io.writefln("%04x: %08x", i, u32ptr[(offset / 4) + i]);
	}
*/
}

fn calcAlign(pos: i32, level: i32) i32
{
	shift := level + 1;
	size := 1 << level;
	return ((pos + size) >> shift) << shift;
}

class RayTracer : Viewer
{
public:
	DagBuffer vbo;

	GLuint query;
	bool queryInFlight;

	GfxShader[3] mShaders;
	string[3] mShaderNames;
	u32 mShaderIndex;
	GfxShader mShader;
	i32 mPatchSize;
	i32 mPatchMinSize;
	i32 mPatchMaxSize;
	i32 mPatchStartLevel;
	i32 mPatchStopLevel;
	i32 mVoxelPower;
	i32 mVoxelPerUnit;


	/**
	 * For ray tracing.
	 * @{
	 */
	GLuint octBuffer;
	GLuint octTexture;
	/**
	 * @}
	 */


public:
	this(GameSceneManager g)
	{
		super(g);
		mVoxelPower = 11;
		mVoxelPerUnit = (1 << mVoxelPower);
		mPatchSize = 16;
		mPatchMinSize = 4;
		mPatchMaxSize = 32;
		mPatchStartLevel = 1;
		mPatchStopLevel = 10;

		vert := cast(string)read("res/power/shaders/raytracer/voxel.vert.glsl");
		geom := cast(string)read("res/power/shaders/raytracer/voxel.geom.glsl");
		frag1 := cast(string)read("res/power/shaders/raytracer/voxel-amd.frag.glsl");
		frag2 := cast(string)read("res/power/shaders/raytracer/voxel-org.frag.glsl");
		frag3 := cast(string)read("res/power/shaders/raytracer/voxel-notrace.frag.glsl");
		mShaders[0] = new GfxShader(vert, geom, frag1, null, null);
		mShaders[1] = new GfxShader(vert, geom, frag2, null, null);
		mShaders[2] = new GfxShader(vert, geom, frag3, null, null);
		mShaderNames[0] = "AMD-OPTZ";
		mShaderNames[1] = "original";
		mShaderNames[2] = "no trace";
		mShader = mShaders[0];

		glGenQueries(1, &query);

		void[] data;
		loadDag("res/alley.dag", out data);

		glGenBuffers(1, &octBuffer);
		glBindBuffer(GL_TEXTURE_BUFFER, octBuffer);
		glBufferData(GL_TEXTURE_BUFFER, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_TEXTURE_BUFFER, 0);

		glGenTextures(1, &octTexture);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glTexBuffer(GL_TEXTURE_BUFFER, GL_R32UI, octBuffer);
		glBindTexture(GL_TEXTURE_BUFFER, 0);

		numMorton := calcNumMorton(mPatchMaxSize);
		b := new DagBuilder(cast(size_t)numMorton);
		foreach (i; 0 .. numMorton) {
			u32[3] vals;
			math.decode3(cast(u64)i, out vals);

			x := cast(i32)vals[0];
			y := cast(i32)vals[1];
			z := cast(i32)vals[2];

			x = x % 2 == 1 ? -x >> 1 : x >> 1;
			y = y % 2 == 1 ? -y >> 1 : y >> 1;
			z = z % 2 == 1 ? -z >> 1 : z >> 1;

			b.add(cast(i8)x, cast(i8)y, cast(i8)z, 1);
		}
		vbo = DagBuffer.make("power/dag", b);
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close()
	{
		super.close();

		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
		mShader = null;
		foreach (ref s; mShaders) {
			s.breakApart();
			s = null;	
		}
	}

	override void keyDown(CtlKeyboard device, int keycode, dchar c, scope const(char)[] m)
	{
		switch (keycode) {
		case 'e':
			mPatchStartLevel++;
			if (mPatchStartLevel > mPatchStopLevel) {
				mPatchStartLevel = 1;
			}
			break;
		case 'r':
			mPatchSize *= 2;
			if (mPatchSize > mPatchMaxSize) {
				mPatchSize = mPatchMinSize;
			}
			break;
		case 't':
			mShaderIndex++;
			if (mShaderIndex >= mShaders.length) {
				mShaderIndex = 0;
			}
			mShader = mShaders[mShaderIndex];
			break;
		default: super.keyDown(device, keycode, c, m);
		}	
	}

	/*
	 *
	 * Viewer methods.
	 *
	 */

	override void renderScene(GfxTarget t)
	{
		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);

		math.Matrix4x4f view;
		view.setToLookFrom(ref camPosition, ref camRotation);

		math.Matrix4x4f proj;
		t.setMatrixToProjection(ref proj, 45.f, 0.0001f, 256.f);
		proj.setToMultiply(ref view);
		proj.transpose();

		// Setup shader.
		mShader.bind();
		setupStatic(ref proj);

		shouldEnd: bool;
		if (!queryInFlight) {
			glBeginQuery(GL_TIME_ELAPSED, query);
			shouldEnd = true;
		}

		// Draw the array.
		glCullFace(GL_FRONT);
		glEnable(GL_CULL_FACE);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);

		glBindVertexArray(vbo.vao);

		foreach (i; mPatchStartLevel .. mPatchStopLevel+1) {
			drawLevel(i);
		}

		glBindVertexArray(0);

		glBindTexture(GL_TEXTURE_BUFFER, 0);
		glDisable(GL_CULL_FACE);

		if (shouldEnd) {
			glEndQuery(GL_TIME_ELAPSED);
			queryInFlight = true;
		}

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);

		// Check for last frames query.
		checkQuery();
	}

	void checkQuery()
	{
		if (!queryInFlight) {
			return;
		}

		available: GLint;
		glGetQueryObjectiv(query, GL_QUERY_RESULT_AVAILABLE, &available);
		if (!available) {
			return;
		}

		timeElapsed: GLuint64;
		glGetQueryObjectui64v(query, GL_QUERY_RESULT, &timeElapsed);
		queryInFlight = false;

		str := `Info:
Elapsed time: %sms
w a s d - move camera
e - patch start level: %s
r - patch size: %s^3
t - shader: %s`;

		text := format(str,
			timeElapsed / 1_000_000_000.0 * 1_000.0,
			mPatchStartLevel,
			mPatchSize,
			mShaderNames[mShaderIndex]);

		updateText(text);
	}

	fn setupStatic(ref mat: math.Matrix4x4f)
	{
		voxelsPerUnit := cast(f32)(1 << mVoxelPower);
		voxelSize := 1.0f / voxelsPerUnit;
		voxelSizeInv := voxelsPerUnit;

		mShader.matrix4("matrix", 1, false, mat.ptr);
		mShader.float3("cameraPos".ptr, camPosition.ptr);
		mShader.float1("voxelSize".ptr, voxelSize);
		mShader.float1("voxelSizeInv".ptr, voxelSizeInv);
	}

	fn drawLevel(level: i32)
	{
		splitPower := mVoxelPower - level;
		splitPerUnit := cast(f32)(1 << splitPower);
		splitSize := 1.0f / splitPerUnit;
		splitSizeInv := splitPerUnit;

		mShader.int1("splitPower".ptr, splitPower);
		mShader.float1("splitSize".ptr, splitSize);
		mShader.float1("splitSizeInv".ptr, splitSizeInv);
		mShader.int1("tracePower".ptr, level);

		pos := math.Vector3f.opCall(camPosition);
		pos.scale(cast(f32)mVoxelPerUnit);
		pos.floor();

		vec := math.Vector3f.opCall(
			cast(f32)calcAlign(cast(i32)pos.x, level),
			cast(f32)calcAlign(cast(i32)pos.y, level),
			cast(f32)calcAlign(cast(i32)pos.z, level));
		mShader.float3("offset".ptr, 1, vec.ptr);

		if (level <= mPatchStartLevel) {
			vec = math.Vector3f.opCall(0.0f, 0.0f, 0.0f);
			mShader.float3("lowerMin".ptr, 1, vec.ptr);
			mShader.float3("lowerMax".ptr, 1, vec.ptr);
		} else {
			lowerLevel := level-1;
			vec.x = cast(f32)calcAlign(cast(i32)pos.x, lowerLevel);
			vec.y = cast(f32)calcAlign(cast(i32)pos.y, lowerLevel);
			vec.z = cast(f32)calcAlign(cast(i32)pos.z, lowerLevel);
			vec -= cast(f32)((mPatchSize / 2) * (1 << lowerLevel));
			mShader.float3("lowerMin".ptr, 1, vec.ptr);
			vec += cast(f32)(mPatchSize * (1 << lowerLevel));
			mShader.float3("lowerMax".ptr, 1, vec.ptr);	
		}

		vec.x = 1; vec.y = 1; vec.z = 1;
		vec.scale(cast(f32)(1 << level));
		mShader.float3("scale".ptr, 1, vec.ptr);

		glDrawArrays(GL_POINTS, 0, calcNumMorton(mPatchSize));
	}

	fn calcNumMorton(dim: i32) i32
	{
		return dim * dim * dim;
	}
}
