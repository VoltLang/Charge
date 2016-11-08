#version 450 core

layout (points) in;
layout (location = 0) in vec3[] inPosition;
layout (binding = 0) uniform isamplerBuffer octree;
layout (triangle_strip, max_vertices = 12) out;
layout (location = 0) out vec3 outPosition;
layout (location = 1) out vec3 outMinEdge;
layout (location = 2) out vec3 outMaxEdge;
layout (location = 3) out flat int outOffset;

uniform mat4 matrix;
uniform vec3 cameraPos;
uniform float voxelSize;
uniform float voxelSizeInv;
uniform int splitPower;
uniform float splitSize;
uniform float splitSizeInv;
uniform vec3 lowerMin;
uniform vec3 lowerMax;


void emit(vec3 pos, vec3 off)
{
	pos += off * splitSize;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

bool findStart(vec3 pos, out int offset)
{
	// Which part of the space the voxel volume occupy.
	vec3 boxMin = vec3(0.0);
	vec3 boxDim = vec3(1.0);

	// Initial node address.
	offset = 0;

	// Subdivid until empty node or found the node for this box.
	for (int i = splitPower; i > 0; i--) {
		// Get the node.
		uint node = uint(texelFetchBuffer(octree, offset).r);

		boxDim *= 0.5f;
		vec3 s = step(boxMin + boxDim, pos);
		boxMin = boxMin + boxDim * s;
		uint select = uint(dot(s, vec3(4, 1, 2)));
		if ((node & (uint(1) << select)) == uint(0)) {
			return false;
		}

		int bits = int(select + 1);
		uint toCount = bitfieldExtract(node, 0, bits);
		int address = int(bitCount(toCount));
		address += int(offset);

		offset = texelFetchBuffer(octree, address).r;
	}

	return true;
}

void main(void)
{
	// Scale position with voxel size.
	vec3 pos = inPosition[0];

	// Is this split voxel position outside of voxel box.
	if (any(lessThan(pos, vec3(0.0))) ||
	    any(greaterThanEqual(pos, vec3(voxelSizeInv)))) {
		return;
	}

	// Is this split voxel of the lower levels area.
	if (all(greaterThanEqual(pos, lowerMin)) &&
	    all(lessThan(pos, lowerMax))) {
		return;
	}

	outMinEdge = inPosition[0] * voxelSize;
	outMaxEdge = outMinEdge + splitSize;

	if (!findStart(outMinEdge, outOffset)) {
		return;
	}

	if (cameraPos.z < outMinEdge.z) {
		emit(outMinEdge, vec3(1.0, 1.0, 0.0));
		emit(outMinEdge, vec3(0.0, 1.0, 0.0));
		emit(outMinEdge, vec3(1.0, 0.0, 0.0));
		emit(outMinEdge, vec3(0.0, 0.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.z > outMaxEdge.z) {
		emit(outMinEdge, vec3(0.0, 0.0, 1.0));
		emit(outMinEdge, vec3(0.0, 1.0, 1.0));
		emit(outMinEdge, vec3(1.0, 0.0, 1.0));
		emit(outMinEdge, vec3(1.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y < outMinEdge.y) {
		emit(outMinEdge, vec3(0.0, 0.0, 0.0));
		emit(outMinEdge, vec3(0.0, 0.0, 1.0));
		emit(outMinEdge, vec3(1.0, 0.0, 0.0));
		emit(outMinEdge, vec3(1.0, 0.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.y > outMaxEdge.y) {
		emit(outMinEdge, vec3(1.0, 1.0, 1.0));
		emit(outMinEdge, vec3(0.0, 1.0, 1.0));
		emit(outMinEdge, vec3(1.0, 1.0, 0.0));
		emit(outMinEdge, vec3(0.0, 1.0, 0.0));
		EndPrimitive();
	}

	if (cameraPos.x < outMinEdge.x) {
		emit(outMinEdge, vec3(0.0, 0.0, 0.0));
		emit(outMinEdge, vec3(0.0, 1.0, 0.0));
		emit(outMinEdge, vec3(0.0, 0.0, 1.0));
		emit(outMinEdge, vec3(0.0, 1.0, 1.0));
		EndPrimitive();
	}

	if (cameraPos.x > outMaxEdge.x) {
		emit(outMinEdge, vec3(1.0, 1.0, 1.0));
		emit(outMinEdge, vec3(1.0, 1.0, 0.0));
		emit(outMinEdge, vec3(1.0, 0.0, 1.0));
		emit(outMinEdge, vec3(1.0, 0.0, 0.0));
		EndPrimitive();
	}
}
