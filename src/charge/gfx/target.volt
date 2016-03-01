// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for Target(s), that is FBO's and DefaultTarget.
 */
module charge.gfx.target;

import charge.sys.file;
import charge.sys.resource;
import charge.gfx.gl;
import charge.gfx.texture;
import charge.math.matrix;


/**
 * Base texture class.
 */
abstract class Target : Resource
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

	abstract void setMatrixToOrtho(ref Matrix4x4f mat);
	abstract void setMatrixToOrtho(ref Matrix4x4f mat, float width, float height);


protected:
	this(GLuint fbo, uint width, uint height)
	{
		this.fbo = fbo;
		this.width = width;
		this.height = height;
		this.target = GL_FRAMEBUFFER;

		super();
	}

	~this()
	{
		if (fbo != 0) {
			glDeleteFramebuffers(1, &fbo);
			fbo = 0;
		}
	}
}

final class DefaultTarget : Target
{
private:
	global DefaultTarget mInstance;


public:
	override final void setMatrixToOrtho(ref Matrix4x4f mat)
	{
		setMatrixToOrtho(ref mat, cast(float)width, cast(float)height);
	}

	override final void setMatrixToOrtho(ref Matrix4x4f mat, float width, float height)
	{
		mat.setToOrtho(0.0f, width, height, 0.0f, -1.0f, 1.0f);
	}

	global DefaultTarget opCall()
	{
		if (mInstance !is null) {
			return mInstance;
		}

		string filename = "%default";

		void* dummy;
		auto t = cast(DefaultTarget)Resource.alloc(typeid(DefaultTarget),
		                                           uri, filename,
		                                           0, out dummy);
		t.__ctor(0, 0);
		mInstance = t;

		return t;
	}

	global void close()
	{
		if (mInstance !is null) {
			mInstance.decRef();
			mInstance = null;
		}
	}


private:
	this(uint width, uint height)
	{
		super(0, width, height);
	}
}

class Framebuffer : Target
{
public:
	Texture tex;


public:
	override final void setMatrixToOrtho(ref Matrix4x4f mat)
	{
		setMatrixToOrtho(ref mat, cast(float)width, cast(float)height);
	}

	override final void setMatrixToOrtho(ref Matrix4x4f mat, float width, float height)
	{
		mat.setToOrtho(0.0f, width, 0.0f, height, -1.0f, 1.0f);
	}

	global Framebuffer make(string name, uint width, uint height)
	{
		uint levels = 1;

		Texture tex = Texture2D.make(name, width, height, levels);

		GLuint fbo;
		glGenFramebuffers(1, &fbo);
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glFramebufferTexture2D(
			GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
			GL_TEXTURE_2D, tex.id, 0);

		glCheckFramebufferError();
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		void* dummy;
		auto t = cast(Framebuffer)Resource.alloc(typeid(Framebuffer),
		                                         uri, name,
		                                         0, out dummy);
		t.__ctor(fbo, tex, width, height);

		return t;
	}


protected:
	this(GLuint fbo, Texture tex, uint width, uint height)
	{
		this.tex = tex;
		super(fbo, width, height);
	}

	~this()
	{
		if (tex !is null) { tex.decRef(); tex = null; }
	}
}
