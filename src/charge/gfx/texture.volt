// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/*!
 * Source file for Texture(s).
 */
module charge.gfx.texture;

import core.exception;

import watt.algorithm;
import watt.text.format;
import watt.math.integer;

import lib.stb.image;

import charge.sys.file;
import charge.sys.resource;
import charge.gfx.gl;


/*!
 * Base texture class.
 */
class Texture : Resource
{
public:
	enum string uri = "tex://";

	target: GLuint;
	id: GLuint;

	width: uint;
	height: uint;
	depth: uint;


public:
	~this()
	{
		if (id != 0) {
			glDeleteTextures(1, &id);
			id = 0;
		}
	}

	final fn bind()
	{
		glBindTexture(target, id);
	}

	final fn unbind()
	{
		glBindTexture(target, 0);
	}


protected:
	this(GLuint target, GLuint id, uint width, uint height, uint depth)
	{
		this.target = target;
		this.id = id;
		this.width = width;
		this.height = height;
		this.depth = depth;

		super();
	}
}

class Texture2D : Texture
{
public:
	global fn makeRGBA8(name: string, width: uint, height: uint,
		levels: uint) Texture2D
	{
		return makeInternal(name, width, height, levels, GL_RGBA8);
	}

	global fn makeDepth24(name: string, width: uint, height: uint,
		levels: uint) Texture2D
	{
		return makeInternal(name, width, height, levels, GL_DEPTH_COMPONENT24);
	}

	global fn makeAlpha(name: string, width: uint, height: uint,
		levels: uint) Texture2D
	{
		return makeInternal(name, width, height, levels, GL_ALPHA);
	}

	global fn makeRGBA8MSAA(name: string, width: uint, height: uint,
		numSamples: uint) Texture2D
	{
		return makeInternalMSAA(name, width, height, numSamples, GL_RGBA8);
	}

	global fn makeDepth24MSAA(name: string, width: uint, height: uint,
		numSamples: uint) Texture2D
	{
		return makeInternalMSAA(name, width, height, numSamples, GL_DEPTH_COMPONENT24);
	}

	global fn makeInternalMSAA(name: string, width: uint, height: uint,
		numSamples: uint, internal: GLuint) Texture2D
	{
		x := cast(GLsizei)width;
		y := cast(GLsizei)height;
		num := cast(GLsizei)numSamples;

		target: GLuint = GL_TEXTURE_2D_MULTISAMPLE;
		id: GLuint;

		glGenTextures(1, &id);
		glBindTexture(target, id);
		glTexImage2DMultisample(target, num, internal, x, y, false);
		glBindTexture(target, 0);
		glCheckError();

		return makeId(name, target, id, width, height);
	}

	global fn makeInternal(name: string, width: uint, height: uint,
		levels: uint, internal: GLuint) Texture2D
	{
		x := cast(int)width;
		y := cast(int)height;
		lvls := cast(int)levels;

		target: GLuint = GL_TEXTURE_2D;
		id: GLuint;

		glGenTextures(1, &id);
		glBindTexture(target, id);
		glTexStorage2D(target, lvls, internal, x, y);
		glBindTexture(target, 0);
		glCheckError();

		return makeId(name, target, id, width, height);
	}

	global fn makeId(name: string, target: GLuint, id: GLuint,
		width: uint, height: uint) Texture2D
	{
		dummy: void*;
		tex := cast(Texture2D)Resource.alloc(typeid(Texture2D),
		                                         uri, name,
		                                         0, out dummy);
		tex.__ctor(target, id, width, height, 1);

		return tex;
	}

	global fn load(p: Pool, filename: string) Texture2D
	{
		file := File.load(filename);
		data := file.data;
		x, y, comp: i32;

		ptr := stbi_load_from_memory(data, out x, out y, out comp, STBI_rgb_alpha);

		// Free and null everything.
		file.decRef(); file = null; data = null;

		if (ptr is null) {
			str := .format("could not load '%s'", filename);
			throw new Exception(filename);
		}

		levels := log2(max(cast(uint)x, cast(uint)y)) + 1;
		tex := makeRGBA8(filename, cast(uint)x, cast(uint)y, levels);
		id := tex.id;
		target := tex.target;
		format := GL_RGBA;

		glCheckError();
		glBindTexture(target, id);
		glTexSubImage2D(
			target,            // target
			0,                 // level
			0,                 // xoffset
			0,                 // yoffset
			x,                 // width
			y,                 // height
			format,            // format
			GL_UNSIGNED_BYTE,  // type
			cast(void*)ptr);
		glGenerateMipmap(GL_TEXTURE_2D);
		glBindTexture(target, 0);
		glCheckError();

		return tex;
	}


protected:
	this(GLuint target, GLuint id, uint width, uint height, uint depth)
	{
		super(target, id, width, height, depth);
	}
}
