// stb_image - v2.10 - public domain image loader - http://nothings.org/stb_image.h
//                     no warranty implied; use at your own risk.
/*!
 * Public interface to stb_image.h, implementation in stb_image.volt.
 */
module lib.stb.image;


alias stbi_uc = ubyte;

enum {
	STBI_default = 0,

	STBI_grey = 1,
	STBI_grey_alpha = 2,
	STBI_rgb = 3,
	STBI_rgb_alpha = 4
}

struct stbi_io_callbacks
{
	read: fn(user: void*, data: stbi_uc*, size: int) int;
	skip: fn(user: void*, n: int) void;
	oef: fn(user: void*) int;
}

fn stbi_info_from_memory(data: void[], out x: int, out y: int, out comp: int) int
{
	return stbi_info_from_memory(cast(stbi_uc*)data.ptr, cast(int)data.length, &x, &y, &comp);
}

fn stbi_load_from_memory(data: void[], out x: int, out y: int, out comp: int, req_comp: int) stbi_uc*
{
	return stbi_load_from_memory(cast(stbi_uc*)data.ptr, cast(int)data.length, &x, &y, &comp, req_comp);
}

extern(C) {
	fn stbi_failure_reason() const(char)*;
	fn stbi_set_flip_vertically_on_load(flag_true_if_should_flip: int);
	fn stbi_info_from_memory(buffer: const(stbi_uc)*, len: int, x: int*, y: int*, comp: int*) int;
	fn stbi_info_from_callbacks(c: const(stbi_io_callbacks)*, user: void*, x: int*, y: int*, comp: int*) int;
	fn stbi_load_from_memory(buffer: const(stbi_uc)*, len: int, x: int*, y: int*, comp: int*, req_comp: int) stbi_uc*;
	fn stbi_load_from_callbacks(clbk: const(stbi_io_callbacks)*, user: void*, x: int*, y: int*, comp: int*, req_comp: int) stbi_uc*;
	fn stbi_image_free(retval_from_stbi_load: void*);
}
