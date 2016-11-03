#version 450 core

layout (location = 0) in vec3 inPosition;

layout (location = 0) out vec3 outPosition;

uniform vec3 offset;
uniform vec3 scale;


void main(void)
{
	outPosition = (inPosition * scale) + offset;
}
