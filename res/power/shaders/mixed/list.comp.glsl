#version 450 core

#define GEOM_POWER 3
layout(local_size_x = 1) in;

layout (binding = 0) uniform usamplerBuffer octree;
layout (binding = 0) uniform atomic_uint counter;

layout (binding = 0, std430) buffer Buffer
{
	uint data[];
};


int calcAddress(uint select, uint node, int offset)
{
	int bits = int(select + 1);
	uint toCount = bitfieldExtract(node, 0, bits);
	int address = int(bitCount(toCount));
	return address + int(offset);
}

void main(void)
{
	// The morton value for this position.
	uint morton = gl_GlobalInvocationID.x;

	// Initial node address.
	int offset = 0;

	// This is a unrolled loop.
	// Subdivide until empty node or found the node for this box.
	// Get the node.
	uint node = texelFetch(octree, offset).r;

	// 3D bit selector, each element is in the range [0, 1].
	// Turn that into scalar in the range [0, 8].
	uint select = (morton >> ((GEOM_POWER-1) * 3)) & uint(0x07);
	if ((node & (uint(1) << select)) == uint(0)) {
		return;
	}

#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);			\
	offset = int(texelFetch(octree, offset).r);			\
	node = uint(texelFetch(octree, offset).r);			\
									\
	select = (morton >> ((GEOM_POWER-counter) * 3)) & uint(0x07);	\
	if ((node & (uint(1) << select)) == uint(0)) {			\
		return;							\
	}								\

#if GEOM_POWER >= 2
	LOOPBODY(2);
#endif
#if GEOM_POWER >= 3
	LOOPBODY(3);
#endif
#if GEOM_POWER >= 4
	LOOPBODY(4);
#endif
#if GEOM_POWER >= 5
	LOOPBODY(5);
#endif
#if GEOM_POWER >= 6
	LOOPBODY(6);
#endif
#if GEOM_POWER >= 7
	LOOPBODY(7);
#endif

	uint index = atomicCounterIncrement(counter);
	data[index * 2] = morton;
	data[index * 2 + 1] = offset;
}
