#version 450 core
#extension GL_ARB_shader_ballot : enable

#define POWER_START %POWER_START%
#define POWER_LEVELS 2
#define POWER_FINAL (POWER_LEVELS + POWER_START)

#define COUNTER_INDEX %COUNTER_INDEX%
#define VOXEL_SRC %VOXEL_SRC%
#define VOXEL_DST %VOXEL_DST%

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

// For the final level AMD cards gets perf
// boost if we are using atomic counters.
layout (binding = 0) uniform atomic_uint counter[8];

layout (binding = 0) uniform usamplerBuffer octree;

layout (binding = 0, std430) buffer BufferCounters
{
	uint inoutCounters[];
};

struct DataFmt
{
	mat4 matrix;
	vec4 planes[4];
	vec4 cameraPos;
};

layout (binding = 1, std430) buffer Data
{
	DataFmt uData;
};

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};

layout (binding = VOXEL_DST, std430) buffer BufferOut
{
	uint outData[];
};


uint calcAddress(uint select, uint node, uint offset)
{
	int bits = int(select);
	uint toCount = bitfieldExtract(node, 0, bits);
	uint address = bitCount(toCount);
	return address + offset + bitfieldExtract(node, 16, 16);
}

void main(void)
{
	// The morton value for this position.
	uint morton = gl_LocalInvocationIndex;

	// Get the initial node adress and the packed position.
	uint offset = gl_WorkGroupID.x * 3;
	uint xy = inData[offset + 0] << POWER_LEVELS;
	uint x = bitfieldExtract(xy, 0, 16);
	uint y = bitfieldExtract(xy, 16, 16);
	uint z = inData[offset + 1] << POWER_LEVELS;
	offset = inData[offset + 2];

	// This is a unrolled loop.
	// Subdivide until empty node or found the node for this box.
	// Get the node.
	uint node = texelFetch(octree, int(offset)).r;

	// 3D bit selector, each element is in the range [0, 1].
	// Turn that into scalar in the range [0, 8].
	uint select = (morton >> ((POWER_LEVELS - 1) * 3)) & uint(0x07);
	if ((node & (uint(1) << select)) == uint(0)) {
		return;
	}

	
#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);				\
	offset = texelFetch(octree, int(offset)).r;				\
	node = texelFetch(octree, int(offset)).r;				\
										\
	select = (morton >> ((POWER_LEVELS-counter) * 3)) & uint(0x07);		\
	if ((node & (uint(1) << select)) == uint(0)) {				\
		return;								\
	}

	// Update the position.
	x += (morton >> (X_SHIFT + 3 - 1)) & 0x2;
	y += (morton >> (Y_SHIFT + 3 - 1)) & 0x2;
	z += (morton >> (Z_SHIFT + 3 - 1)) & 0x2;

	// Some constants
	float invDiv2 =    1.0 / (1 << (POWER_FINAL - 1));
	float invDiv =     1.0 / (1 << (POWER_FINAL    ));
	float invDivHalf = 1.0 / (1 << (POWER_FINAL + 1));
	float invRadii2 = invDiv2 * sqrt(2.0);

	vec4 v = vec4(vec3(x, y, z) * invDiv + invDiv, 1.0);

	// Test against frustum.
#if POWER_FINAL > 3
	uint bitsIndex = gl_SubGroupInvocationARB & 0x38;
	uint b = uint(ballotARB(dot(v, uData.planes[gl_SubGroupInvocationARB & 0x03]) < -invRadii2) >> bitsIndex);
	if ((b & 0x0f) != 0) {
		return;
	}
#endif

	// Final loop body.
	LOOPBODY(2);

	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, int(offset)).r;

	// Update the position.
	x += (morton >> X_SHIFT) & 0x1;
	y += (morton >> Y_SHIFT) & 0x1;
	z += (morton >> Z_SHIFT) & 0x1;

	uint index = atomicAdd(inoutCounters[COUNTER_INDEX], 1) * 3;
	outData[index + 0] = bitfieldInsert(x, y, 16, 16);
	outData[index + 1] = z;
	outData[index + 2] = offset;
}