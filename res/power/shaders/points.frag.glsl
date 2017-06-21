#version 450 core

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat uint inColor;
layout (location = 0) out vec4 outColor;


void main(void)
{
	outColor = unpackUnorm4x8(inColor);
}
