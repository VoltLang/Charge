// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Texture(s).
 */
module charge.gfx.texture;

import lib.stb.image;

import charge.sys.file;
import charge.sys.resource;
import charge.gfx.gl;


/**
 * Base texture class.
 */
class Texture : Resource
{
public:
	enum string uri = "tex://";

	GLuint id;
	GLuint target;

	uint width;
	uint height;
	uint depth;


public:
	final void bind()
	{
		glBindTexture(target, id);
	}

	final void unbind()
	{
		glBindTexture(target, 0);
	}


protected:
	this(GLuint id, GLuint target, uint width, uint height, uint depth)
	{
		this.id = id;
		this.target = target;
		this.width = width;
		this.height = height;
		this.depth = depth;

		super();
	}

	~this()
	{
		if (id != 0) {
			glDeleteTextures(1, &id);
			id = 0;
		}
	}
}

class Texture2D : Texture
{
public:
	global Texture2D make(string name, uint width, uint height, uint levels,
		bool depth = false)
	{
		int x = cast(int)width;
		int y = cast(int)height;
		int lvls = cast(int)levels;

		GLuint id;
		GLuint target = GL_TEXTURE_2D;
		GLuint internal = depth ? GL_DEPTH_COMPONENT24 : GL_RGBA8;

		glGenTextures(1, &id);
		glBindTexture(target, id);
		glTexStorage2D(target, lvls, internal, x, y);
		glBindTexture(target, 0);
		glCheckError();

		void* dummy;
		auto tex = cast(Texture2D)Resource.alloc(typeid(Texture2D),
		                                         uri, name,
		                                         0, out dummy);
		tex.__ctor(id, target, cast(uint) x, cast(uint) y, 1);

		return tex;
	}

	global Texture2D load(Pool p, string filename)
	{
		File file = File.load(filename);
		void[] data = file.data;
		int x, y, comp;

		auto ptr = stbi_load_from_memory(data, out x, out y, out comp, STBI_rgb_alpha);

		// Free and null everything.
		file.decRef(); file = null; data = null;

		if (ptr is null) {
			throw new Exception("could not load '" ~ filename ~ "'");
		}

		uint levels = log2(max(cast(uint)x, cast(uint)y)) + 1;
		auto tex = make(filename, cast(uint)x, cast(uint)y, levels);
		GLuint id = tex.id;
		GLuint target = tex.target;
		GLuint format = GL_RGBA;

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
	this(GLuint id, GLuint target, uint width, uint height, uint depth)
	{
		super(id, target, width, height, depth);
	}
}
