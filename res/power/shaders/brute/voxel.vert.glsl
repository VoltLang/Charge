#version 450 core

layout (location = 0) in ivec3 inPosition;
layout (location = 1) in uint inOffset;

layout (location = 0) out ivec3 outPosition;
layout (location = 1) out uint outOffset;


void main(void)
{
	outPosition = inPosition;
	outOffset = inOffset;
}
