// Copyright © 2013, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

import core.stdc.stdio : printf;
import charge.core : chargeCore, Core, CoreOptions;
import lib.gles;

global string vertexShader = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute mediump vec3 position;

void main(void)
{
	gl_Position = vec4(position, 1.0);
}
`;

global string fragmentShader = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

void main(void)
{
	gl_FragColor = vec4(0.0, 0.0, 1.0, 0.0);
}
`;

class Main
{
public:
	this(Core c)
	{
		printf("ctor\n".ptr);
		c.closeDg = close;
		c.renderDg = render;

		GLuint v, f, program, buf;
		const(char)* p;
		char[500] msg;

		/* Compile the vertex shader */
		p = vertexShader.ptr;
		v = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(v, 1, &p, null);
		glCompileShader(v);
		glGetShaderInfoLog(v, 500, null, msg.ptr);
		printf("vertex shader info: %s\n".ptr, msg.ptr);

		/* Compile the fragment shader */
		p = fragmentShader.ptr;
		f = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(f, 1, &p, null);
		glCompileShader(f);
		glGetShaderInfoLog(f, 500, null, msg.ptr);
		printf("fragment shader info: %s\n".ptr, msg.ptr);

		/* Create and link the shader program */
		program = glCreateProgram();
		glAttachShader(program, v);
		glAttachShader(program, f);
		glBindAttribLocation(program, 0, "position".ptr);

		glLinkProgram(program);
		glGetProgramInfoLog(program, 500, null, msg.ptr);
		printf("program info: %s\n".ptr, msg.ptr);

		glUseProgram(program);

		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);


		float[] verts = new float[](9);
		verts[0] =  0.0f; verts[1] =  0.1f; verts[2] =  0.0f;
		verts[3] =  0.1f; verts[4] = -0.1f; verts[5] =  0.0f;
		verts[6] = -0.1f; verts[7] = -0.1f; verts[8] =  0.0f;
		glGenBuffers(1, &buf);
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferData(GL_ARRAY_BUFFER, 9 * 4, verts.ptr, GL_STATIC_DRAW);

		return;
	}

	void close()
	{
		printf("close\n".ptr);

		return;
	}

	void render()
	{
		glClear(GL_COLOR_BUFFER_BIT);

		glVertexAttribPointer(0, 3, GL_FLOAT, 0, 3 * 4, null);
		glEnableVertexAttribArray(0);

		glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
		return;
	}
}

int main()
{
	auto c = chargeCore(new CoreOptions());
	auto m = new Main(c);

	return c.loop();
}
