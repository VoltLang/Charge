#version 450 core

layout (early_fragment_tests) in;
layout (location = 0) in flat int inPrim;

layout (std430, binding = 0) buffer VisibilityBuffer {
	int visible[];
};

void main()
{
	visible[inPrim] = 1;
}
