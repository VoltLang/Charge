#version 450 core

layout (location = 0) out       vec3 outPosition;
layout (location = 1) out flat  vec3 outMinEdge;
layout (location = 2) out flat  vec3 outMaxEdge;
layout (location = 3) out flat ivec3 outArray;

uniform mat4 matrix;


void main(void)
{
	// Generate coords on the fly.
	float x = float(gl_VertexID & 0x1);
	float y = float((gl_VertexID >> 1) & 0x1);
	float z = float((gl_VertexID >> 2) & 0x1);

	outMinEdge = vec3(0);
	outMaxEdge = vec3(1);
	outPosition = vec3(x, y, z);
	outArray = ivec3(129, 255, 255);
	gl_Position = matrix * vec4(x, y, z, 1.0);

}
