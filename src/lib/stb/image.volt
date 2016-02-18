// stb_image - v2.10 - public domain image loader - http://nothings.org/stb_image.h
//                     no warranty implied; use at your own risk.
/**
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
	int function(void* user, stbi_uc* data, int size) read;
	void function(void* user, int n) skip;
	int function(void* user) oef;
}

int stbi_info_from_memory(void[] data, out int x, out int y, out int comp)
{
	return stbi_info_from_memory(cast(stbi_uc*)data.ptr, cast(int)data.length, &x, &y, &comp);
}

stbi_uc* stbi_load_from_memory(void[] data, out int x, out int y, out int comp, int req_comp)
{
	return stbi_load_from_memory(cast(stbi_uc*)data.ptr, cast(int)data.length, &x, &y, &comp, req_comp);
}

extern(C) {
	const(char)* stbi_failure_reason();
	void stbi_set_flip_vertically_on_load(int flag_true_if_should_flip);
	int stbi_info_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp);
	int stbi_info_from_callbacks(const(stbi_io_callbacks)* c, void* user, int* x, int* y, int* comp);
	stbi_uc* stbi_load_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp, int req_comp);
	stbi_uc* stbi_load_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* comp, int req_comp);
	void stbi_image_free(void* retval_from_stbi_load);
}
