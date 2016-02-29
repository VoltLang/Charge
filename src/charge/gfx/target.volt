// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Target(s), that is FBO's and DefaultTarget.
 */
module charge.gfx.target;

import charge.sys.file;
import charge.sys.resource;
import charge.gfx.gl;


/**
 * Base texture class.
 */
class Target : Resource
{
public:
	enum string uri = "target://";

	GLuint fbo;
	GLuint target;

	uint width;
	uint height;

public:
	final void bind()
	{
		glBindFramebuffer(target, fbo);
		glViewport(0, 0, cast(int)width, cast(int)height);
	}

	final void unbind()
	{
		glBindFramebuffer(target, 0);
	}

protected:
	this(GLuint fbo, uint width, uint height)
	{
		this.fbo = fbo;
		this.width = width;
		this.height = height;
		this.target = GL_FRAMEBUFFER;

		super();
	}

	override void collect()
	{
		if (fbo != 0) {
			glDeleteFramebuffers(1, &fbo);
			fbo = 0;
		}
	}
}

final class DefaultTarget : Target
{
	global DefaultTarget instance;

	global DefaultTarget make(uint width, uint height)
	{
		string filename = "%default";

		void* dummy;
		auto t = cast(DefaultTarget)Resource.alloc(typeid(DefaultTarget),
		                                           uri, filename,
		                                           0, out dummy);
		t.__ctor(width, height);
		instance = t;

		return t;
	}

private:
	this(uint width, uint height)
	{
		super(0, width, height);
	}
}
