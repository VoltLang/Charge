#version 450 core

layout (location = 0) in flat ivec3 array;
layout (location = 0) out vec4 outColor;


int getBits(int select)
{
	int data = (select >= 4) ? array.y : array.x;
	return (data >> (4 * (select % 4))) & 0xff;
}

void main(void)
{
	outColor = vec4(
		float(getBits(0)) / 255.0,
		float(getBits(1)) / 255.0,
		float(getBits(2)) / 255.0,
		0);
}
