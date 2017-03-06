#version 450 core

layout (points) in;
layout (location = 0) in int[] inPosition;
layout (location = 1) in int[] inOffset;
layout (location = 2) in int[] inVisible;

layout (points, max_vertices = 1) out;
layout (xfb_buffer = 0, xfb_stride = 8) out OutputBlock
{
	layout (xfb_offset = 0) uint outPosition;
	layout (xfb_offset = 4) uint outOffset;
};

void main(void)
{
	if (inVisible[0] == 0) {
		return;
	}

	outPosition = inPosition[0];
	outOffset = inOffset[0];
	EmitVertex();
	EndPrimitive();
}
