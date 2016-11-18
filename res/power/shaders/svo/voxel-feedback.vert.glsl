#version 450 core

#define POW 3

layout (location = 0) in vec3 inPosition;
layout (location = 0) out vec3 outPosition;

uniform vec3 positionOffset;
uniform vec3 positionScale;


void main(void)
{
	outPosition = (inPosition * positionScale) + positionOffset;
}
