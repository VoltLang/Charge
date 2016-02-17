// Copyright © 2013-2016, Jakob Bornecrantz.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module examples.gl;

import charge.ctl;
import charge.game.app;
import charge.gfx.shader;
import charge.core : chargeCore, chargeQuit, Core, CoreOptions;
import lib.gl;


enum string vertexShaderES = `
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

enum string fragmentShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

void main(void)
{
	gl_FragColor = vec4(0.0, 0.0, 1.0, 0.0);
}
`;

enum string vertexShader450 = `
#version 450 core

layout (location = 0) in vec3 position;

void main(void)
{
	gl_Position = vec4(position, 1.0);
}
`;

enum string fragmentShader450 = `
#version 450 core

layout (location = 0) out vec4 color;

void main(void)
{
	color = vec4(0.0, 0.0, 1.0, 0.0);
}
`;

class Game : App
{
public:
	float val;
	Shader shader;
	GLuint buf;

public:
	this(string[] args)
	{
		super();

		input.keyboard.down = down;

		if (GL_VERSION_4_5) {
			shader = new Shader(vertexShader450, fragmentShader450, null, null);
		} else if (GL_ES_VERSION_2_0 || GL_ARB_ES2_compatibility) {
			shader = new Shader(vertexShaderES, fragmentShaderES, ["position"], null);
		}
		shader.bind();
		val = 0.1f;

		float[] verts = new float[](9);
		verts[0] =  0.0f; verts[1] =  0.1f; verts[2] =  0.0f;
		verts[3] =  0.1f; verts[4] = -0.1f; verts[5] =  0.0f;
		verts[6] = -0.1f; verts[7] = -0.1f; verts[8] =  0.0f;
		glGenBuffers(1, &buf);
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferData(GL_ARRAY_BUFFER, 9 * 4, cast(void*)verts.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	override void close()
	{
		shader.breakApart();

		super.close();
	}

	override void logic()
	{
		val = val + 0.003f;
		if (val > 0.3f) {
			val = 0.1f;
		}
	}

	override void render()
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);


		// Setup vertex buffer and update the data a bit.
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferSubData(GL_ARRAY_BUFFER, 4, 4, cast(void*)&val);
		glVertexAttribPointer(0, 3, GL_FLOAT, 0, 3 * 4, null);
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);


		// Draw the triangle.
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
	}

	override void idle(long)
	{
		// This method intentionally left empty.
	}

	void down(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		chargeQuit();
	}
}
