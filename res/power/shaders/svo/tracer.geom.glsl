#version 450 core

#define VOXEL_POWER %%
#define OCCLUDE_POWER %%
#define GEOM_POWER %%

#define DIVISOR (1 << (OCCLUDE_POWER + GEOM_POWER))
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

	ipos.x = ((int(select) >> 2)      ) << (GEOM_POWER-1);
	ipos.y = ((int(select)     ) & 0x1) << (GEOM_POWER-1);
	ipos.z = ((int(select) >> 1) & 0x1) << (GEOM_POWER-1);

#define LOOPBODY(counter) \
		offset = calcAddress(select, node, offset);			\
		offset = texelFetch(octree, offset).r;				\
		node = uint(texelFetch(octree, offset).r);			\
										\
		select = (morton >> ((GEOM_POWER-counter) * 3)) & 0x07;		\
		if ((node & (uint(1) << select)) == uint(0)) {			\
			return false;						\
		}								\
										\
		ipos.x += ((int(select) >> 2)      ) << (GEOM_POWER-counter);	\
		ipos.y += ((int(select)     ) & 0x1) << (GEOM_POWER-counter);	\
		ipos.z += ((int(select) >> 1) & 0x1) << (GEOM_POWER-counter);	\


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

void emit(vec3 minEdge, vec3 maxEdge, ivec3 ipos, vec3 off)
{
	vec3 pos = ipos;
	pos += off;
	pos *= DIVISOR_INV;
	outMinEdge = minEdge;
	outMaxEdge = maxEdge;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

void main(void)
{
	ivec3 ipos;
	if (!findStart(ipos, outOffset)) {
		return;
	}

	ipos += inPosition[0] << GEOM_POWER;

	vec3 minEdge = vec3(ipos) * DIVISOR_INV;
	vec3 maxEdge = minEdge + vec3(1.0) * DIVISOR_INV;

	if (cameraPos.z < minEdge.z) {
		emit(minEdge, maxEdge, ipos, vec3(1.0, 1.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 1.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 0.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 0.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.z > maxEdge.z) {
		emit(minEdge, maxEdge, ipos, vec3(0.0, 0.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 1.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 0.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y < minEdge.y) {
		emit(minEdge, maxEdge, ipos, vec3(0.0, 0.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 0.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 0.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 0.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y > maxEdge.y) {
		emit(minEdge, maxEdge, ipos, vec3(1.0, 1.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 1.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 1.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 1.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.x < minEdge.x) {
		emit(minEdge, maxEdge, ipos, vec3(0.0, 0.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 1.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 0.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(0.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.x > maxEdge.x) {
		emit(minEdge, maxEdge, ipos, vec3(1.0, 1.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 1.0, 0.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 0.0, 1.0));
		emit(minEdge, maxEdge, ipos, vec3(1.0, 0.0, 0.0));
		EndPrimitive();
	}
}
