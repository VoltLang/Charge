// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.textures;

import io = watt.io;

import watt.algorithm;
import watt.math.floating;

import lib.gl.gl45;

import gfx = charge.gfx;

import charge.gfx.gl;


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
	data := new u32[](TexSize * TexSize);

	tex: GLuint;
	glCreateTextures(GL_TEXTURE_CUBE_MAP, 1, &tex);
	glTextureStorage2D(tex,
		TexLevels,
		GL_RGBA8,
		TexSize, TexSize);

	glBindTexture(GL_TEXTURE_CUBE_MAP, tex);
	foreach (level; 0 .. TexLevels) {
		genCubeEdgeFactor(tex, data, level);
	}
	glBindTexture(GL_TEXTURE_CUBE_MAP, 0);

	glCheckError();

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
		glSamplerParameteri(sampler,
			GL_TEXTURE_WRAP_S,
			GL_CLAMP_TO_EDGE);
		glSamplerParameteri(sampler,
			GL_TEXTURE_WRAP_T,
			GL_CLAMP_TO_EDGE);
		glSamplerParameteri(sampler,
			GL_TEXTURE_WRAP_R,
			GL_CLAMP_TO_EDGE);
//		max: f32;
//		glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &max);
//		glSamplerParameterf(sampler,
//			GL_TEXTURE_MAX_ANISOTROPY_EXT,
//			max); // Not supported on 3D
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

			data[count++] = getValue3D(iY, iX, iZ, size);
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


fn genCubeEdgeFactor(tex: GLuint, data: u32[], level: i32)
{
	size := getSizeOfLevel(level);

	foreach (i; 0 .. 6) {
		getDataForFace(i, data, size);

		glTexSubImage2D(
			GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(u32)i,
			level,
			0, // xoffset
			0, // yoffset
			cast(GLsizei)size,
			cast(GLsizei)size,
			GL_RGBA,
			GL_UNSIGNED_BYTE,
			cast(void*)data.ptr);
	}
}

fn getDataForFace(face: i32, data: u32[], size: u32)
{
	count: u32;

	if (size <= 4) {
		val: u32;
		switch (face) {
		default: assert(false);
		case 0: val = 0x0080_80FF; break; // 0 == X Positive
		case 1: val = 0x0080_8000; break; // 0 == X Negative
		case 2: val = 0x0080_FF80; break; // 0 == Y Positive
		case 3: val = 0x0080_0080; break; // 0 == Y Negative
		case 4: val = 0x00FF_8080; break; // 0 == Z Positive
		case 5: val = 0x0000_8080; break; // 0 == Z Negative
		}

		pixels := size * size;
		foreach (i; 0  .. pixels) {
			data[count++] = val;
		}

		return;
	}

	switch (face) {
	default: assert(false);
	case 0: // 0 == X Positive
		iX := size - 1;
		foreach (iY; 0 .. size) {
			foreach (iZ; 0 .. size) {
				x := iX;
				y := size - iY - 1;
				z := size - iZ - 1;
				data[count++] = getValueCube(x, y, z, size);
			}
		}
		break;
	case 1: // 0 == X Negative
		iX := 0u;
		foreach (iY; 0 .. size) {
			foreach (iZ; 0 .. size) {
				x := iX;
				y := size - iY - 1;
				z := iZ;
				data[count++] = getValueCube(x, y, z, size);
			}
		}
		break;
	case 2: // 0 == Y Positive
		iY := size - 1;
		foreach (iZ; 0 .. size) {
			foreach (iX; 0 .. size) {
				data[count++] = getValueCube(iX, iY, iZ, size);
			}
		}
		break;
	case 3: // 0 == Y Negative
		iY := 0u;
		foreach (iZ; 0 .. size) {
			foreach (iX; 0 .. size) {
				x := iX;
				y := iY;
				z := size - iZ - 1;
				data[count++] = getValueCube(x, y, z, size);
			}
		}
		break;
	case 4: // 0 == Z Positive
		iZ := size - 1;
		foreach (iY; 0 .. size) {
			foreach (iX; 0 .. size) {
				x := iX;
				y := size - iY - 1;
				z := iZ;
				data[count++] = getValueCube(x, y, z, size);
			}
		}
		break;
	case 5: // 0 == Z Negative
		iZ := 0u;
		foreach (iY; 0 .. size) {
			foreach (iX; 0 .. size) {
				x := size - iX - 1;
				y := size - iY - 1;
				z := iZ;
				data[count++] = getValueCube(x, y, z, size);
			}
		}
		break;
	}
}

fn getValueCube(iX: size_t, iY: size_t, iZ: size_t, size: size_t) u32
{
	half := size / 2;
	sx := iX < half ? -1.0 : 1.0;
	sy := iY < half ? -1.0 : 1.0;
	sz := iZ < half ? -1.0 : 1.0;

	nx := getAxis(iX, size) * sx;
	ny := getAxis(iY, size) * sy;
	nz := getAxis(iZ, size) * sz;
	len := sqrt(nx * nx + ny * ny + nz * nz);
	nx = (nx / len) * 0.5 + 0.5;
	ny = (ny / len) * 0.5 + 0.5;
	nz = (nz / len) * 0.5 + 0.5;

	bx := cast(u8)(nx * 255.0);
	by := cast(u8)(ny * 255.0);
	bz := cast(u8)(nz * 255.0);

	return bz << 16u | by << 8u | bx << 0u;
}

fn getValue3D(iX: size_t, iY: size_t, iZ: size_t, size: size_t) u32
{
	x := getFactor(iX, size);
	y := getFactor(iY, size);
	z := getFactor(iZ, size);

	v := min(min(
		max(x, y),
		max(x, z)),
			max(z, y));
	f := cast(u8)(v * 255.0);

	nx := cast(u8)(getAxis(iX, size) * 255.0);
	ny := cast(u8)(getAxis(iY, size) * 255.0);
	nz := cast(u8)(getAxis(iZ, size) * 255.0);

	return f << 24u | nz << 16u | ny << 8u | nx << 0u;
}

fn getAxis(val: size_t, size: size_t) f64
{
	t := max(size / 8, 1);
	if (size < 2) {
		t = 0;
	}

	v := val / (size - 1.0);
	v = pow(1 - v * 2.0, 8.0);


	return v;
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
