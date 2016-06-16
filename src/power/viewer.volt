// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.viewer;

import watt.math;
import io = watt.io;
import watt.io.file;

import charge.ctl;
import charge.sys.memory;
import charge.sys.resource;
import charge.core;
import charge.game;
import charge.gfx.gl;

import gfx = charge.gfx;
import math = charge.math;


class Viewer : GameScene
{
public:
	CtlInput input;
	VoxelBuffer vbo;
	float rotation;
	gfx.Shader voxelShader;


public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		input = CtlInput.opCall();
		vbo = doit();

		voxelShader = new gfx.Shader(vertexShaderES, fragmentShaderES,
		                             ["position", "color"], null);
	}

	override void close()
	{
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (voxelShader !is null) {
			voxelShader.breakApart();
			voxelShader = null;
		}
	}


	/*
	 *
	 * Our own methods and helpers.
	 *
	 */

	void down(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
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

	override void render(gfx.Target t)
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
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 128.f);
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

	override void assumeControl()
	{
		input.keyboard.down = down;
	}

	override void dropControl()
	{
		if (input.keyboard.down is down) {
			input.keyboard.down = null;
		}
	}
}

/**
 * VBO used for Voxels.
 */
class VoxelBuffer : gfx.Buffer
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

struct Vertex
{
	float x, y, z;
	math.Color4b color;

	Vertex opCall(f32 x, f32 y, f32 z, math.Color4b color)
	{
		Vertex vert;
		vert.x = x;
		vert.y = y;
		vert.z = z;
		vert.color = color;
		return vert;
	}
}

class VoxelBuilder : Builder
{
	this(size_t num)
	{
		reset(num);
	}

	final void reset(size_t num = 0)
	{
		resetStore(12 * num * typeid(Vertex).size);
	}

	final void addCube(f32 x, f32 y, f32 z, math.Color4b color)
	{
		Vertex[24] vert;
		vert[ 0] = Vertex.opCall(  x, 1+y,   z, color);
		vert[ 1] = Vertex.opCall(  x,   y,   z, color);
		vert[ 2] = Vertex.opCall(1+x,   y,   z, color);
		vert[ 3] = Vertex.opCall(1+x, 1+y,   z, color);

		vert[ 4] = Vertex.opCall(  x, 1+y, 1+z, color);
		vert[ 5] = Vertex.opCall(  x,   y, 1+z, color);
		vert[ 6] = Vertex.opCall(1+x,   y, 1+z, color);
		vert[ 7] = Vertex.opCall(1+x, 1+y, 1+z, color);

		vert[ 8] = Vertex.opCall(  x, 1+y,   z, color);
		vert[ 9] = Vertex.opCall(  x,   y,   z, color);
		vert[10] = Vertex.opCall(  x,   y, 1+z, color);
		vert[11] = Vertex.opCall(  x, 1+y, 1+z, color);

		vert[12] = Vertex.opCall(1+x, 1+y,   z, color);
		vert[13] = Vertex.opCall(1+x,   y,   z, color);
		vert[14] = Vertex.opCall(1+x,   y, 1+z, color);
		vert[15] = Vertex.opCall(1+x, 1+y, 1+z, color);

		vert[16] = Vertex.opCall(  x,   y, 1+z, color);
		vert[17] = Vertex.opCall(  x,   y,   z, color);
		vert[18] = Vertex.opCall(1+x,   y,   z, color);
		vert[19] = Vertex.opCall(1+x,   y, 1+z, color);

		vert[20] = Vertex.opCall(  x, 1+y, 1+z, color);
		vert[21] = Vertex.opCall(  x, 1+y,   z, color);
		vert[22] = Vertex.opCall(1+x, 1+y,   z, color);
		vert[23] = Vertex.opCall(1+x, 1+y, 1+z, color);

		add(vert.ptr, 24);
	}

	final void add(Vertex* vert, size_t num)
	{
		add(cast(void*)vert, num * typeid(Vertex).size);
	}

	alias add = Builder.add;

	final void bake(out GLuint vao, out GLuint buf, out GLsizei num)
	{
		// Setup vertex buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, buf);

		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)length, ptr, GL_STATIC_DRAW);

		stride := cast(GLsizei)typeid(Vertex).size;
		glVertexAttribPointer(0, 3, GL_FLOAT, 0, stride, null);
		glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, 1, stride, cast(void*)(3 * 4));
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);

		num = cast(GLsizei)length / stride;
	}
}

class Builder
{
private:
	void* mPtr;
	size_t mPos;
	size_t mSize;

public:
	final @property void* ptr() { return mPtr; }
	final @property size_t length() { return mPos; }

	~this()
	{
		close();
	}

	final void close()
	{
		if (mPtr !is null) {
			cFree(mPtr);
			mPtr = null;
		}
		mPos = 0;
		mSize = 0;
	}

	final void add(void* input, size_t size)
	{
		if (mPos + size >= mSize) {
			mSize += mPos + size;
			mPtr = cRealloc(mPtr, mSize);
		}
		mPtr[mPos .. mPos + size] = input[0 .. size];
		mPos += size;
	}

private:
	void resetStore(size_t size)
	{
		if (mSize < size) {
			cFree(mPtr);
			mPtr = cMalloc(size);
			mSize = size;
		}
		mPos = 0;
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
	numVoxels : size_t;

	void setBit(Voxel v) {
		i := math.encode(v.x, v.z, v.y);
		bitArray[i / 64] |= 1UL << (i % 64);
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
			bitArray = new u64[]((x*y*z)/64);
			break;
		case "XYZI":
			numVoxels = *cast(u32*)ptr;
			voxels := (cast(Voxel*)(ptr + 4))[0 .. numVoxels];
			foreach (v; voxels) {
				setBit(v);
			}
			break;
		default:
		}
		ptr = ptr + c.chunkSize;
	}

	vb := new VoxelBuilder(numVoxels);

	// Loop trough voxels in morton order.
	foreach (i, b; bitArray) {
		if (b == 0) {
			continue;
		}

		foreach (k; 0UL .. 64UL) {
			if (b & (1UL << k)) {
				cord : u32[3];
				num := i * 64 + k;
				math.decode3(num, out cord);
				color := math.Color4b.opCall(
					cast(u8)(cord[0]*5), cast(u8)(cord[1]*5),
					cast(u8)(cord[2]*5), 255);
				vb.addCube(
					cast(f32)cord[0],
					cast(f32)cord[1],
					cast(f32)cord[2],
					color);
			}
		}
	}

	return VoxelBuffer.make("voxels", vb);
}


enum string vertexShaderES = `
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

enum string fragmentShaderES = `
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
