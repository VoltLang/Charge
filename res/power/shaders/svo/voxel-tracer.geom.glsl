#version 450 core

#define POW 4
#define LOOP 4
#define DIVISOR pow(2, float(POW))
#define DIVISOR_INV (1.0/DIVISOR)

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


bool findStart(out ivec3 ipos, out int offset)
{
	// The morton value for this position.
	uint morton = gl_PrimitiveIDIn;

	// Initial node address.
	offset = inOffset[0];

	// Subdivid until empty node or found the node for this box.
	for (int i = (LOOP-1); i >= 0; i--) {
		// Get the node.
		uint node = uint(texelFetch(octree, offset).r);

		// 3D bit selector, each element is in the range [0, 1].
		// Turn that into scalar in the range [0, 8].
		uint select = (morton >> (i * 3)) & 0x07;
		if ((node & (uint(1) << select)) == uint(0)) {
			return false;
		}

		ipos += ivec3(
			(select >> 2) & 0x1,
			(select     ) & 0x1,
			(select >> 1) & 0x1) << i;

		int bits = int(select + 1);
		uint toCount = bitfieldExtract(node, 0, bits);
		int address = int(bitCount(toCount));
		address += int(offset);

		offset = texelFetch(octree, address).r;
	}

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

	ipos += inPosition[0] * 8;

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
