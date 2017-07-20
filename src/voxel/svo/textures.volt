// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.textures;

import io = watt.io;
import watt.algorithm;
import watt.math.floating;
import charge.gfx;


fn createEdge3DSampler() GLuint
{
	return createEdgeSampler(cube:false);
}

fn createEdge3DTexture() GLuint
{
	data := new u32[](TexSize * 2);

	glCheckError();
	tex: GLuint;
	glCreateTextures(GL_TEXTURE_3D, 1, &tex);
	glTextureStorage3D(tex,
		TexLevels,
		GL_RGBA8,
		TexSize, TexSize, TexSize);


	gen3DEdgeFactor(tex, data, 0);
	glGenerateTextureMipmap(tex);

	foreach (level; 1 .. TexLevels - 4) {
		size := cast(u32)(1 << (TexLevels - level - 1));

		foreach (iZ; 0 .. size) {
			gen3DEdgeFactor(tex, data, level, iZ);
		}
	}

	return tex;
}

fn createEdgeCubeSampler() GLuint
{
	return createEdgeSampler(cube:true);
}

fn createEdgeCubeTexture() GLuint
{
	glCheckError();

	data := new u8[](TexSize * 2 * 4);

	tex: GLuint;
	glCreateTextures(GL_TEXTURE_CUBE_MAP, 1, &tex);
	glTextureStorage2D(tex,
		TexLevels,
		GL_R8,
		TexSize, TexSize);

	glCheckError();

	genCubeEdgeFactor(tex, data, 0);
	glGenerateTextureMipmap(tex);

	foreach (level; 1 .. TexLevels - 5) {
		genCubeEdgeFactor(tex, data, level);
	}

	return tex;
}


private:

fn createEdgeSampler(cube: bool) GLuint
{
	sampler: GLuint;
	glCreateSamplers(1, &sampler);

	glSamplerParameteri(sampler,
		GL_TEXTURE_MIN_FILTER,
		GL_LINEAR_MIPMAP_LINEAR);
	glSamplerParameteri(sampler,
		GL_TEXTURE_MAG_FILTER,
		GL_LINEAR);

	if (cube) {
		max: f32;
		glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &max);
		glSamplerParameterf(sampler,
			GL_TEXTURE_MAX_ANISOTROPY_EXT,
			max); // Not supported on 3D
	} else {
		glSamplerParameteri(sampler,
			GL_TEXTURE_WRAP_S,
			GL_REPEAT);
		glSamplerParameteri(sampler,
			GL_TEXTURE_WRAP_T,
			GL_REPEAT);
		glSamplerParameteri(sampler,
			GL_TEXTURE_WRAP_R,
			GL_REPEAT);
		glSamplerParameterf(sampler,
			GL_TEXTURE_LOD_BIAS,
			-1.0f); // Fake anisotropy for 3D
	}

	return sampler;
}

enum TexLevels = 8;
enum TexSize = 1 << (TexLevels - 1);
enum TexPowFactor = 8;


fn getSizeOfLevel(level: i32) u32
{
	return cast(u32)(1 << (TexLevels - level - 1));
}

fn gen3DEdgeFactor(tex: GLuint, data: u32[], level: i32)
{
	size := getSizeOfLevel(level);
	foreach (iZ; 0 .. size) {
		gen3DEdgeFactor(tex, data, level, iZ);
	}
}

fn gen3DEdgeFactor(tex: GLuint, data: u32[], level: i32, iZ: u32)
{
	size := getSizeOfLevel(level);
	count: u32;

	z := getFactor(iZ, size);
	foreach (iX; 0 .. size) {
		x := getFactor(iX, size);

		foreach (iY; 0 .. size) {
			y := getFactor(iY, size);
			v := min(min(
				max(x, y),
				max(x, z)),
					max(z, y));

			data[count++] = getValue(iX, iY, iZ, size);
		}
	}

	glTextureSubImage3D(tex,
		level,
		0,                 // xoffset
		0,                 // yoffset
		cast(GLint)iZ,     // zoffset
		cast(GLsizei)size, // xsize
		cast(GLsizei)size, // ysize
		1,                 // zsize
		GL_RGBA,
		GL_UNSIGNED_BYTE,
		cast(void*)data.ptr);
}

fn genCubeEdgeFactor(tex: GLuint, data: u8[], level: i32)
{
	size := getSizeOfLevel(level);

	count: u32;
	foreach (iX; 0 .. size) {
		x := getFactor(iX, size);

		foreach (iY; 0 .. size) {
			y := getFactor(iY, size);
			v := max(x, y);

			data[count++] = cast(u8)(v * 255.0);
		}
	}

	foreach (i; 0 .. 6) {

		foreach (iX; 0 .. size) {
			x := getFactor(iX, size);

			foreach (iY; 0 .. size) {
				y := getFactor(iY, size);
				v := max(x, y);

				data[count++] = cast(u8)(v * 255.0);
			}
		}

		glTextureSubImage3D(tex,
			level,
			0, // xoffset
			0, // yoffset
			i, // zoffset
			cast(GLsizei)size,
			cast(GLsizei)size,
			1,
			GL_RGBA,
			GL_UNSIGNED_BYTE,
			cast(void*)data.ptr);
	}
}

fn getValue(iX: size_t, iY: size_t, iZ: size_t, size: size_t) u32
{
	x := getFactor(iX, size);
	y := getFactor(iY, size);
	z := getFactor(iZ, size);

	v := min(min(
		max(x, y),
		max(x, z)),
			max(z, y));
	f := cast(u8)(v * 255.0);

	nx := getAxis(iX, size);
	ny := getAxis(iY, size);
	nz := getAxis(iZ, size);

	return f << 24u | nz << 16u | nx << 8u | ny << 0u;
}

fn getAxis(val: size_t, size: size_t) u8
{
	t := max(size / 8, 1);
	if (size < 2) {
		t = 0;
	}

	v := val / (size - 1.0);
	v = pow(1 - v * 2.0, 8.0);


	return cast(u8)(v * 255.0);
}

fn getFactor(val: size_t, size: size_t) f64
{
	t := max(size / 8, 1);

	if (size <= 2) {
		return 0.0;
	} else if (val < t || val > (size - t - 1)) {
		return 1.0;
	} else {
		return 0.0;
	}
}
