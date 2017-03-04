#version 450 core

#define LIST_POWER %%
#define SIZE (1 << LIST_POWER)
layout(local_size_x = SIZE, local_size_y = SIZE, local_size_z = SIZE) in;

layout (binding = 0) uniform usamplerBuffer octree;
layout (binding = 0) uniform atomic_uint counter;

layout (binding = 0, std430) buffer BufferIn
{
	uint inData[];
};

layout (binding = 1, std430) buffer BufferOut
{
	uint outData[];
};


uint calcAddress(uint select, uint node, uint offset)
{
	int bits = int(select + 1);
	uint toCount = bitfieldExtract(node, 0, bits);
	uint address = bitCount(toCount);
	return address + offset;
}

void main(void)
{
	// The morton value for this position.
	uint morton = gl_LocalInvocationIndex;

	// Get the initial node adress and extra morton bits.
	uint offset = (gl_WorkGroupID.x + gl_NumWorkGroups.x * gl_WorkGroupID.y) * 2;
	uint extra = inData[offset + 0];
	offset =     inData[offset + 1];

	// This is a unrolled loop.
	// Subdivide until empty node or found the node for this box.
	// Get the node.
	uint node = texelFetch(octree, int(offset)).r;

	// 3D bit selector, each element is in the range [0, 1].
	// Turn that into scalar in the range [0, 8].
	uint select = (morton >> ((LIST_POWER-1) * 3)) & uint(0x07);
	if ((node & (uint(1) << select)) == uint(0)) {
		return;
	}

#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);			\
	offset = texelFetch(octree, int(offset)).r;			\
	node = texelFetch(octree, int(offset)).r;			\
									\
	select = (morton >> ((LIST_POWER-counter) * 3)) & uint(0x07);	\
	if ((node & (uint(1) << select)) == uint(0)) {			\
		return;							\
	}								\

#if LIST_POWER >= 2
	LOOPBODY(2);
#endif
#if LIST_POWER >= 3
	LOOPBODY(3);
#endif
#if LIST_POWER >= 4
#error
#endif

	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, int(offset)).r;

	uint index = atomicCounterIncrement(counter) * 2;
	outData[index] = morton | (extra << (LIST_POWER * 3));
	outData[index + 1] = offset;
}
