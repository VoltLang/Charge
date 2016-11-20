#version 450 core

#define OCCLUDE_POWER %%
#define OCCLUDE_VOXELS (1 << OCCLUDE_POWER)
#define OCCLUDE_SIZE (1.0 / OCCLUDE_VOXELS)

layout (points) in;
layout (location = 0) in ivec3[] inPosition;
layout (triangle_strip, max_vertices = 12) out;
layout (location = 0) out flat int outPrim;

uniform mat4 matrix;
uniform vec3 cameraPos;


void emit(vec3 pos)
{
	outPrim = gl_PrimitiveIDIn;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

void main(void)
{
	ivec3 ipos = inPosition[0];
	vec3 minEdge = ipos * OCCLUDE_SIZE;
	vec3 maxEdge = minEdge + OCCLUDE_SIZE;

	if (cameraPos.z < minEdge.z) {
		emit(vec3(maxEdge.x, maxEdge.y, minEdge.z));
		emit(vec3(minEdge.x, maxEdge.y, minEdge.z));
		emit(vec3(maxEdge.x, minEdge.y, minEdge.z));
		emit(vec3(minEdge.x, minEdge.y, minEdge.z));
		EndPrimitive();
	}

	if (cameraPos.z > maxEdge.z) {
		emit(vec3(minEdge.x, minEdge.y, maxEdge.z));
		emit(vec3(minEdge.x, maxEdge.y, maxEdge.z));
		emit(vec3(maxEdge.x, minEdge.y, maxEdge.z));
		emit(vec3(maxEdge.x, maxEdge.y, maxEdge.z));
		EndPrimitive();
	}

	if (cameraPos.y < minEdge.y) {
		emit(vec3(minEdge.x, minEdge.y, minEdge.z));
		emit(vec3(minEdge.x, minEdge.y, maxEdge.z));
		emit(vec3(maxEdge.x, minEdge.y, minEdge.z));
		emit(vec3(maxEdge.x, minEdge.y, maxEdge.z));
		EndPrimitive();
	}

	if (cameraPos.y > maxEdge.y) {
		emit(vec3(maxEdge.x, maxEdge.y, maxEdge.z));
		emit(vec3(minEdge.x, maxEdge.y, maxEdge.z));
		emit(vec3(maxEdge.x, maxEdge.y, minEdge.z));
		emit(vec3(minEdge.x, maxEdge.y, minEdge.z));
		EndPrimitive();
	}

	if (cameraPos.x < minEdge.x) {
		emit(vec3(minEdge.x, minEdge.y, minEdge.z));
		emit(vec3(minEdge.x, maxEdge.y, minEdge.z));
		emit(vec3(minEdge.x, minEdge.y, maxEdge.z));
		emit(vec3(minEdge.x, maxEdge.y, maxEdge.z));
		EndPrimitive();
	}

	if (cameraPos.x > maxEdge.x) {
		emit(vec3(maxEdge.x, maxEdge.y, maxEdge.z));
		emit(vec3(maxEdge.x, maxEdge.y, minEdge.z));
		emit(vec3(maxEdge.x, minEdge.y, maxEdge.z));
		emit(vec3(maxEdge.x, minEdge.y, minEdge.z));
		EndPrimitive();
	}
}
