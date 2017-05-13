#version 450 core
#extension GL_ARB_shader_ballot : enable

#undef LIST_DO_TAG
#define POWER_START %POWER_START%
#define POWER_LEVELS %POWER_LEVELS%
#define POWER_DISTANCE %POWER_DISTANCE%
#define POWER_FINAL (POWER_LEVELS + POWER_START)

#define VOXEL_SRC %VOXEL_SRC%
#define VOXEL_DST1 %VOXEL_DST1%
#define VOXEL_DST2 %VOXEL_DST2%

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#if POWER_LEVELS == 2
layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
#elif POWER_LEVELS == 3
layout (local_size_x = 64, local_size_y = 8, local_size_z = 1) in;
#else
#error
#endif

layout (binding = 0) uniform usamplerBuffer octree;
layout (binding = 0) uniform atomic_uint counter[8];

uniform vec4 planes[8];
uniform vec3 cameraPos;

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};

layout (binding = VOXEL_DST1, std430) buffer BufferOut1
{
	uint outData1[];
};

layout (binding = VOXEL_DST2, std430) buffer BufferOut2
{
	uint outData2[];
};


uvec4 unpack_2_10_10_10(uint data)
{
	return uvec4(
		(data >>  0) & 0x3FF,
		(data >> 10) & 0x3FF,
		(data >> 20) & 0x3FF,
		(data >> 30) & 0x003);
}

uint pack_2_10_10_10_unsafe(uvec4 data)
{
	return data.w << 30 | data.z << 20 | data.y << 10 | data.x;
}

uvec4 unpack_16_16_16_16(uint data1, uint data2)
{
	return uvec4(
		(data1 >>  0) & 0xFFFF,
		(data1 >> 16) & 0xFFFF,
		(data2 >>  0) & 0xFFFF,
		(data2 >> 16) & 0xFFFF);
}

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

	// Get the initial node adress and the packed position.
	uint offset = (gl_WorkGroupID.x + gl_NumWorkGroups.x * gl_WorkGroupID.y) * 3;
	uint packedPos1 = inData[offset + 0] << POWER_LEVELS;
	uint packedPos2 = inData[offset + 1] << POWER_LEVELS;
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

	packedPos1 = packedPos1 |
		(((select >> X_SHIFT) & 0x1) << (POWER_LEVELS - 1 +  0)) |
		(((select >> Y_SHIFT) & 0x1) << (POWER_LEVELS - 1 + 16));
	packedPos2 = packedPos2 |
		(((select >> Z_SHIFT) & 0x1) << (POWER_LEVELS - 1 +  0));
	
#define LOOPBODY(counter) \
	offset = calcAddress(select, node, offset);				\
	offset = texelFetch(octree, int(offset)).r;				\
	node = texelFetch(octree, int(offset)).r;				\
										\
	select = (morton >> ((POWER_LEVELS-counter) * 3)) & uint(0x07);		\
	if ((node & (uint(1) << select)) == uint(0)) {				\
		return;								\
	}									\
										\
	packedPos1 = packedPos1 |						\
		(((select >> X_SHIFT) & 0x1) << (POWER_LEVELS - counter +  0)) |\
		(((select >> Y_SHIFT) & 0x1) << (POWER_LEVELS - counter + 16));	\
	packedPos2 = packedPos2 |						\
		(((select >> Z_SHIFT) & 0x1) << (POWER_LEVELS - counter +  0));	\


	// After this loop level each group of 8 lanes holds one box of voxels.
#if POWER_LEVELS == 3
	LOOPBODY(2);
#endif

	// Some constants
	float invDiv2 =    1.0 / (1 << (POWER_FINAL - 1));
	float invDiv =     1.0 / (1 << (POWER_FINAL    ));
	float invDivHalf = 1.0 / (1 << (POWER_FINAL + 1));
	float invRadii2 = invDiv2 * sqrt(2.0);

	// Unpack the position.
	uvec3 upos = unpack_16_16_16_16(packedPos1, packedPos2).xyz;
	vec4 v = vec4(vec3(upos) * invDiv + invDiv, 1.0);

#if POWER_FINAL > 4
	uint bitsIndex = gl_SubGroupInvocationARB & 0x38;
	uint b = uint(ballotARB(dot(v, planes[gl_SubGroupInvocationARB & 0x03]) < -invRadii2) >> bitsIndex);
	if ((b & 0x0f) != 0) {
		return;
	}
#endif

	// Final loop body.
#if POWER_LEVELS == 2
	LOOPBODY(2);
#elif POWER_LEVELS == 3
	LOOPBODY(3);
#endif

	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, int(offset)).r;

#ifdef LIST_DO_TAG
	vec3 v1 = v.xyz - cameraPos;
	float l = dot(v1, v1);
	if (l > POWER_DISTANCE) {
		uint index = atomicCounterIncrement(counter[VOXEL_DST2]) * 3;
		outData2[index + 0] = packedPos1;
		outData2[index + 1] = packedPos2;
		outData2[index + 2] = offset;
		//outData2[index + 3] = 0;
		return;
	}
#endif

	uint index = atomicCounterIncrement(counter[VOXEL_DST1]) * 3;
	outData1[index + 0] = packedPos1;
	outData1[index + 1] = packedPos2;
	outData1[index + 2] = offset;
	//outData1[index + 3] = 0;
}
