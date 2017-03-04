#version 450 core

layout (location = 0) out       vec3 outPosition;
layout (location = 1) out flat  vec3 outMinEdge;
layout (location = 2) out flat ivec3 outArray;

uniform mat4 matrix;

layout (binding = 0, std430) buffer BufferIn
{
	uint inData[];
};


void main(void)
{
	uint index = gl_VertexID >> 3;

	uint inPos = inData[index];

	// Generate coords on the fly.
	vec3 pos = vec3(
		float(gl_VertexID & 0x1),
		float((gl_VertexID >> 1) & 0x1),
		float((gl_VertexID >> 2) & 0x1)
	);

	pos.x += float(inPos & 0xff) * 8;

	outMinEdge = vec3(0);
	outPosition = pos;
	outArray = ivec3(129, 2164260864, 255);
	gl_Position = matrix * vec4(pos, 1.0);
}