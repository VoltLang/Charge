// Copyright © 2013, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

import core.stdc.stdio : printf;
import charge.gfx.shader;
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
	float val;
	Shader shader;

public:
	this(Core c)
	{
		printf("ctor\n".ptr);
		c.setClose(close);
		c.setRender(render);

		shader = new Shader(vertexShader, fragmentShader, ["position"], null);
		shader.bind();
		val = 0.1f;

		GLuint buf;

		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);

		float[] verts = new float[](9);
		verts[0] =  0.0f; verts[1] =  0.1f; verts[2] =  0.0f;
		verts[3] =  0.1f; verts[4] = -0.1f; verts[5] =  0.0f;
		verts[6] = -0.1f; verts[7] = -0.1f; verts[8] =  0.0f;
		glGenBuffers(1, &buf);
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferData(GL_ARRAY_BUFFER, 9 * 4, cast(void*)verts.ptr, GL_STATIC_DRAW);
	}

	void close()
	{
		shader.breakApart();

		printf("close\n".ptr);
	}

	void render()
	{
		glClear(GL_COLOR_BUFFER_BIT);

		val = val + 0.003f;
		if (val > 0.3f) {
			val = 0.1f;
		}

		glBufferSubData(GL_ARRAY_BUFFER, 4, 4, cast(void*)&val);

		glVertexAttribPointer(0, 3, GL_FLOAT, 0, 3 * 4, null);
		glEnableVertexAttribArray(0);

		glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
	}
}

int main()
{
	auto c = chargeCore(new CoreOptions());
	auto m = new Main(c);

	return c.loop();
}
