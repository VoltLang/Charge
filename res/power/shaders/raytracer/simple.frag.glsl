#version 450 core

layout (location = 0) in vec3 inPosition;
layout (location = 0) out vec4 outColor;

uniform int splitPower;


void main(void)
{
	int traceSize = 1 << splitPower;
	outColor = vec4(mod(inPosition * traceSize, 1.0), 1.0);
}
