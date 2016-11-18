#version 450 core

#define VOXEL_POWER 11
#define FEEDBACK_POWER 3
#define GEOM_POWER 4

#define DIVISOR (1 << (FEEDBACK_POWER + GEOM_POWER))
#define DIVISOR_INV (1.0 / DIVISOR)

layout (points) in;
layout (location = 0) in ivec3[] inPosition;
layout (location = 1) in int[] inOffset;

layout (triangle_strip, max_vertices = 12) out;
layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat vec3 outMinEdge;
layout (location = 2) out flat vec3 outMaxEdge;
layout (location = 3) out flat int outOffset;

layout (binding = 0) uniform isamplerBuffer octree;
uniform mat4 matrix;
uniform vec3 cameraPos;

int calcAddress(uint select, uint node, int offset)
{
	int bits = int(select + 1);
	uint toCount = bitfieldExtract(node, 0, bits);
	int address = int(bitCount(toCount));
	return address + int(offset);
}

bool findStart(out ivec3 ipos, out int offset)
{
	// The morton value for this position.
	uint morton = gl_PrimitiveIDIn;

	// Initial node address.
	offset = inOffset[0];

	// This is a unrolled loop.
	// Subdivide until empty node or found the node for this box.
	// Get the node.
	uint node = uint(texelFetch(octree, offset).r);

	// 3D bit selector, each element is in the range [0, 1].
	// Turn that into scalar in the range [0, 8].
	uint select = (morton >> ((GEOM_POWER-1) * 3)) & 0x07;
	if ((node & (uint(1) << select)) == uint(0)) {
		return false;
	}
	ipos += ivec3(
		(select >> 2) & 0x1,
		(select     ) & 0x1,
		(select >> 1) & 0x1) << (GEOM_POWER-1);


#define LOOPBODY(counter) \
		offset = calcAddress(select, node, offset);		\
		offset = texelFetch(octree, offset).r;			\
		node = uint(texelFetch(octree, offset).r);		\
									\
		select = (morton >> ((GEOM_POWER-counter) * 3)) & 0x07;	\
		if ((node & (uint(1) << select)) == uint(0)) {		\
			return false;					\
		}							\
									\
		ipos += ivec3(						\
			(select >> 2) & 0x1,				\
			(select     ) & 0x1,				\
			(select >> 1) & 0x1) << (GEOM_POWER-counter);		\

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
#if GEOM_POWER >= 8
	LOOPBODY(8);
#endif

	// Final offset calculation
	offset = calcAddress(select, node, offset);
	offset = texelFetch(octree, offset).r;
	return true;
}

void emit(ivec3 ipos, vec3 off)
{
	vec3 pos = ipos;
	pos += off;
	pos *= DIVISOR_INV;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

void main(void)
{
	ivec3 ipos = ivec3(0);
	if (!findStart(ipos, outOffset)) {
		return;
	}

	ipos += inPosition[0] * (1 << GEOM_POWER);

	outMinEdge = vec3(ipos) * DIVISOR_INV;
	outMaxEdge = outMinEdge + vec3(1.0) * DIVISOR_INV;

	if (cameraPos.z < outMinEdge.z) {
		emit(ipos, vec3(1.0, 1.0, 0.0));
		emit(ipos, vec3(0.0, 1.0, 0.0));
		emit(ipos, vec3(1.0, 0.0, 0.0));
		emit(ipos, vec3(0.0, 0.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.z > outMaxEdge.z) {
		emit(ipos, vec3(0.0, 0.0, 1.0));
		emit(ipos, vec3(0.0, 1.0, 1.0));
		emit(ipos, vec3(1.0, 0.0, 1.0));
		emit(ipos, vec3(1.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y < outMinEdge.y) {
		emit(ipos, vec3(0.0, 0.0, 0.0));
		emit(ipos, vec3(0.0, 0.0, 1.0));
		emit(ipos, vec3(1.0, 0.0, 0.0));
		emit(ipos, vec3(1.0, 0.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y > outMaxEdge.y) {
		emit(ipos, vec3(1.0, 1.0, 1.0));
		emit(ipos, vec3(0.0, 1.0, 1.0));
		emit(ipos, vec3(1.0, 1.0, 0.0));
		emit(ipos, vec3(0.0, 1.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.x < outMinEdge.x) {
		emit(ipos, vec3(0.0, 0.0, 0.0));
		emit(ipos, vec3(0.0, 1.0, 0.0));
		emit(ipos, vec3(0.0, 0.0, 1.0));
		emit(ipos, vec3(0.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.x > outMaxEdge.x) {
		emit(ipos, vec3(1.0, 1.0, 1.0));
		emit(ipos, vec3(1.0, 1.0, 0.0));
		emit(ipos, vec3(1.0, 0.0, 1.0));
		emit(ipos, vec3(1.0, 0.0, 0.0));
		EndPrimitive();
	}
}
