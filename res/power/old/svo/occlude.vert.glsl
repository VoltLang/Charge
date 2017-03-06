#version 450 core

layout (location = 0) in ivec3 inPosition;

layout (location = 0) out ivec3 outPosition;


void main(void)
{
	outPosition = inPosition;
}
