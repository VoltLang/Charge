// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
module charge.gfx.gl;

public import lib.gl;

import io = watt.io;


fn glCheckError(loc: string = __LOCATION__) GLuint
{
	err := glGetError();
	if (err == GL_NO_ERROR) {
		return err;
	}

	code: string;
	switch (err) {
	case GL_NO_ERROR: code = "GL_NO_ERROR"; break;
	case GL_INVALID_ENUM: code = "GL_INVALID_ENUM"; break;
	case GL_INVALID_VALUE: code = "GL_INVALID_VALUE"; break;
	case GL_INVALID_OPERATION: code = "GL_INVALID_OPERATION"; break;
	case GL_INVALID_FRAMEBUFFER_OPERATION: code = "GL_INVALID_FRAMEBUFFER_OPERATION"; break;
	case GL_OUT_OF_MEMORY: code = "GL_OUT_OF_MEMORY"; break;
	// Not in core
	//case GL_STACK_UNDERFLOW: code = "GL_STACK_UNDERFLOW"; break;
	//case GL_STACK_OVERFLOW: code = "GL_STACK_OVERFLOW"; break;
	default: code = new "${err}"; break;
	}

	io.error.write(new "${loc} error: ${code}");
	io.error.flush();
	return err;
}

fn glCheckFramebufferError(loc: string = __LOCATION__) GLuint
{
	status := glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status == GL_FRAMEBUFFER_COMPLETE) {
		return status;
	}

	code: string;
	switch (status) {
	case GL_FRAMEBUFFER_UNDEFINED:
		code = "GL_FRAMEBUFFER_UNDEFINED"; break;
	case GL_FRAMEBUFFER_UNSUPPORTED:
		code = "GL_FRAMEBUFFER_UNSUPPORTED"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
		code = "GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS:
		code = "GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS"; break;
	case GL_FRAMEBUFFER_COMPLETE:
		code = "GL_FRAMEBUFFER_COMPLETE"; break;
	default:
		code = new "${status}"; break;
	}

	io.error.write(new "${loc} error: ${code}");
	io.error.flush();
	return status;
}
