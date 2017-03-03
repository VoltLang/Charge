#version 450 core

#define VOXEL_POWER 11
#define CUBE_POWER 9

#define DIVISOR (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / DIVISOR)

layout (points) in;
layout (location = 0) in ivec3[] inPosition;
layout (location = 1) in uint[] inOffset;

layout (triangle_strip, max_vertices = 12) out;
layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat vec3 outMinEdge;
layout (location = 2) out flat vec3 outMaxEdge;
layout (location = 3) out flat uint outOffset;

layout (binding = 0) uniform isamplerBuffer octree;
uniform mat4 matrix;
uniform vec3 cameraPos;


void emit(vec3 minEdge, vec3 maxEdge, ivec3 ipos, vec3 off)
{
	vec3 pos = ipos;
	pos += off;
	pos *= DIVISOR_INV;
	outOffset = inOffset[0];
	outMinEdge = minEdge;
	outMaxEdge = maxEdge;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

void main(void)
{
	ivec3 ipos = inPosition[0];
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
