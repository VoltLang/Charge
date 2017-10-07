// This file contains a common data struct for all svo voxel shaders.

struct PerObject
{
	// MVP matrix
	mat4 matrix;
	// Frustum planes.
	vec4 planes[4];
	// The position of the camera (w is padding).
	vec4 cameraPos;
};

struct DataFmt
{
	// Per object entries.
	PerObject objs[256];

	// Per level distance information.
	float dists[32];

	// Sprite size factor.
	float pointScale;
};
