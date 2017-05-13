#version 450 core

#define POWER_START %%
#define POWER_LEVELS %%
#define SPLIT_SIZE (1.0 / (1 << POWER_START))

#define VOXEL_POWER (POWER_START + POWER_LEVELS)
#define TRACER_POWER POWER_LEVELS

#define X_SHIFT %X_SHIFT%
#define Y_SHIFT %Y_SHIFT%
#define Z_SHIFT %Z_SHIFT%

#define X_MUL (1 << X_SHIFT)
#define Y_MUL (1 << Y_SHIFT)
#define Z_MUL (1 << Z_SHIFT)

layout (location = 0) in vec3 inPosition;
layout (location = 1) in flat uint inColor;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;


void main(void)
{
	outColor = unpackUnorm4x8(inColor);
}
