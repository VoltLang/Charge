#version 450 core

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat vec3 inMinEdge;
layout (location = 0) out vec4 outColor;

uniform int splitPower;


void main(void)
{
	float traceSize = float(1 << splitPower);
	outColor = vec4((inPosition - inMinEdge) * traceSize, 1.0);
}
