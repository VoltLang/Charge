// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver 1.0).
module charge.gfx.gl;

static import watt.conv;
static import watt.io.std;

public import lib.gl;

void glCheckError(const(char)[] file = __FILE__, int line = __LINE__)
{
	auto err = glGetError();
	if (!err) {
		return;
	}

	string code;
	switch (err) {
	case GL_INVALID_ENUM: code = "GL_INVALID_ENUM"; break;
	case GL_INVALID_OPERATION: code = "GL_INVALID_OPERATION"; break;
	case GL_INVALID_VALUE: code = "GL_INVALID_VALUE"; break;
	default: code = watt.conv.toString(err); break;
	}

	watt.io.std.writefln("%s:%s error: %s", file, line, code);
}

uint max(uint x, uint y)
{
	return x > y ? x : y;
}

uint log2(uint x)
{
	uint ans = 0 ;
	while (x = x >> 1) {
		ans++;
	}

	return ans;
}
