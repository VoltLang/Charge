// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module charge.gfx.buffer;

import charge.gfx.gl;
import charge.sys.resource;


class Buffer : Resource
{
public:
	enum string uri = "buf://";
	GLuint vao;
	GLuint buf;


protected:
	void deleteBuffers()
	{
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
		if (vao) { glDeleteVertexArrays(1, &vao); vao = 0; }	
	}


private:
	this(GLuint vao, GLuint buf)
	{
		this.vao = vao;
		this.buf = buf;
		super();
	}

	~this()
	{
		deleteBuffers();
	}
}
