// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver 1.0).
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
	void _ctor(GLuint id, GLuint target, uint width, uint height, uint depth)
	{
		this.id = id;
		this.target = target;
		this.width = width;
		this.height = height;
		this.depth = depth;

		super._ctor();
	}

	override void collect()
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
	global Texture2D load(Pool p, string filename)
	{
		File file = File.load(filename);
		void[] data = file.data;
		int x, y, comp;

		stbi_set_flip_vertically_on_load(true);
		auto ptr = stbi_load_from_memory(data, out x, out y, out comp, STBI_rgb_alpha);

		// Free and null everything.
		file.decRef(); file = null; data = null;

		if (ptr is null) {
			throw new Exception("could not load '" ~ filename ~ "'");
		}

		GLuint id;
		GLuint target = GL_TEXTURE_2D;
		GLuint internal = GL_RGBA8;
		GLuint format = GL_RGBA;
		GLsizei levels = cast(GLsizei)log2(
			max(cast(uint)x, cast(uint)y)) + 1;

		// Clear any error
		glCheckError();

		glGenTextures(1, &id);
		glBindTexture(target, id);
		glCheckError();

		glTexStorage2D(target, levels, internal, x, y);
		glCheckError();

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
		glCheckError();

		glGenerateMipmap(GL_TEXTURE_2D);
		glCheckError();

		glBindTexture(target, 0);
		glCheckError();

		void* dummy;
		auto tex = cast(Texture2D)Resource.alloc(typeid(Texture2D),
		                                         uri, filename,
		                                         0, out dummy);
		tex._ctor(id, target, cast(uint) x, cast(uint) y, 1);

		return tex;
	}
}
