#version 450 core

#define UPPER 6
#define POW 9
#define LOOP (POW - UPPER)
#define DIVISOR pow(2, float(POW))
#define DIVISOR_INV (1.0/DIVISOR)

layout (points) in;
layout (location = 0) in ivec3[] inPosition;
layout (location = 1) in uint[] inOffset;
layout (binding = 0) uniform isamplerBuffer octree;

#define POINTS
#ifdef POINTS
layout (points, max_vertices = 1) out;
#else
layout (triangle_strip, max_vertices = 12) out;
#endif
layout (location = 0) out vec4 outColor;

uniform mat4 matrix;
uniform vec3 cameraPos;


bool findStart(out ivec3 ipos, out uint offset, out vec4 color)
{
	// The morton value for this position.
	uint morton = gl_PrimitiveIDIn;

	// Initial node address.
	offset = inOffset[0];

	// Subdivid until empty node or found the node for this box.
	for (int i = LOOP;;) {
		// Get the node.
		uint node = uint(texelFetchBuffer(octree, int(offset)).r);

		// Found color, return the voxol color.
		if ((node & uint(0x80000000)) != uint(0)) {
			uint alpha = (node & uint(0x3F000000)) >> uint(24);
			uint red = (node & uint(0x00FF0000)) >> uint(16);
			uint green = (node & uint(0x0000FF00)) >> uint(8);
			uint blue = (node & uint(0x000000FF));
			color = vec4(red, green, blue, 255) / 255.0;
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
			color = vec4(ipos * DIVISOR_INV, 1.0);
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
		offset = (node & uint(0x3FFFFFFF)) + select;
	}

	return true;
}

void emit(ivec3 ipos, vec3 off)
{
	vec3 pos = ipos;
	pos += off;
	pos *= DIVISOR_INV;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

void main(void)
{
	uint outOffset;
	ivec3 ipos;
	if (!findStart(ipos, outOffset, outColor)) {
		return;
	}

	ipos += inPosition[0] * 8;

#ifdef POINTS
	gl_PointSize = 4.0;
	gl_Position = matrix * vec4(vec3(ipos) * DIVISOR_INV, 1.0);
	EmitVertex();
	EndPrimitive();
#else
	vec3 outMinEdge = vec3(ipos) * DIVISOR_INV;
	vec3 outMaxEdge = outMinEdge + vec3(1.0) * DIVISOR_INV;

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
#endif
}
