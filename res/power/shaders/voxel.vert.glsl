#version 450 core

layout (location = 0) in ivec3 inPosition;
layout (location = 1) in ivec3 inMod;

layout (location = 0) out ivec3 outPosition;


void main(void)
{
	outPosition = inPosition + inMod * 16;
}
