#version 450 core

#define POW 3
#define DIVISOR pow(2, float(POW))
#define DIVISOR_INV (1.0/DIVISOR)

layout (points) in;

layout (location = 0) in ivec3[] inPosition;
layout (location = 1) in uint[] inOffset;
layout (points, max_vertices = 1) out;
layout (xfb_buffer = 0, xfb_stride = 8) out outputBlock
{
	layout (xfb_offset = 0) uint outPosition;
	layout (xfb_offset = 4) uint outOffset;
};

layout (binding = 0) uniform isamplerBuffer octree;



uniform vec3 cameraPos;


bool findStart(out ivec3 ipos, out uint offset)
{
	// The morton value for this position.
	uint morton = gl_PrimitiveIDIn;

	// Initial node address.
	offset = inOffset[0];

	// Subdivid until empty node or found the node for this box.
	for (int i = POW;;) {
		// Get the node.
		uint node = uint(texelFetchBuffer(octree, int(offset)).r);

		// Found color, return the voxol color.
		if ((node & uint(0x80000000)) == uint(31)) {
			return true;
		}

		// Found empty node, so return false to not emit a box.
		// We could have hit this if we hit a color.
		if ((node & uint(0xC0000000)) != uint(0)) {
			return false;
		}

		// Reach end of tree, but has more none-empty node.
		// Just color it to the position and say that something is here.
		if (i-- <= 0) {
			return true;
		}

		// 3D bit selector, each element is in the range [0, 1].
		// Turn that into scalar in the range [0, 8].
		uint select = (morton >> (i * 3)) & 0x07;

		ipos += ivec3(
			(select     ) & 0x1,
			(select >> 1) & 0x1,
			(select >> 2)      ) << i;

		// Use the selector and node pointer to get the new node position.
		offset = int((node & uint(0x3FFFFFFF)) + select);
	}

	return true;
}

void main(void)
{
#if 0
	ivec3 ipos = inPosition[0];
	outOffset = inOffset[0];
	if (outOffset == 0) {
		return;
	}
#else
	ivec3 ipos;
	if (!findStart(ipos, outOffset)) {
		return;
	}
#endif

	ipos += inPosition[0] * 8;
	outPosition = uint(dot(ipos, ivec3(1, 256, 256*256)));
	outOffset = outOffset;
	EmitVertex();
	EndPrimitive();
}
