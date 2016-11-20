#version 450 core

layout (location = 0) in int inPosition;
layout (location = 1) in int inOffset;
layout (location = 2) in int inVisible;

layout (location = 0) out int outPosition;
layout (location = 1) out int outOffset;
layout (location = 2) out int outVisible;


void main(void)
{
	outPosition = inPosition;
	outOffset = inOffset;
	outVisible = inVisible;
}
