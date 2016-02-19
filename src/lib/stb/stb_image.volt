// stb_image - v2.10 - public domain image loader - http://nothings.org/stb_image.h
//                     no warranty implied; use at your own risk.
/**
 * Port of stb_image.h to volt, does not include everything.
 */
module lib.stb.stb_image;

import lib.stb.image : stbi_uc, stbi_io_callbacks,
	STBI_default, STBI_grey, STBI_grey_alpha,
	STBI_rgb, STBI_rgb_alpha;
import charge.sys.memory : cMalloc, cRealloc, cFree;


/*
 *
 * Public interface.
 *
 */

extern(C) void stbi_set_flip_vertically_on_load(int flag_true_if_should_flip)
{
	stbi__vertically_flip_on_load = flag_true_if_should_flip;
}

extern(C) const(char)* stbi_failure_reason()
{
	return stbi__g_failure_reason;
}

extern(C) int stbi_info_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp)
{
	stbi__context s;
	stbi__start_mem(&s, buffer, len);
	return stbi__info_main(&s, x, y, comp);
}

extern(C) int stbi_info_from_callbacks(const(stbi_io_callbacks)* c, void* user, int* x, int* y, int* comp)
{
	stbi__context s;
	stbi__start_callbacks(&s, cast(stbi_io_callbacks*) c, user);
	return stbi__info_main(&s, x, y, comp);
}

extern(C) stbi_uc* stbi_load_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp, int req_comp)
{
	stbi__context s;
	stbi__start_mem(&s, buffer, len);
	return stbi__load_flip(&s, x, y, comp, req_comp);
}

extern(C) stbi_uc* stbi_load_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* comp, int req_comp)
{
	stbi__context s;
	stbi__start_callbacks(&s, cast(stbi_io_callbacks*) clbk, user);
	return stbi__load_flip(&s, x, y, comp, req_comp);
}

extern(C) void stbi_image_free(void* retval_from_stbi_load)
{
	cFree(retval_from_stbi_load);
}


/*
 *
 * Internal code
 *
 */

private:


local const(char)* stbi__g_failure_reason;

local int stbi__vertically_flip_on_load = 0;

static int stbi__err(const(char)* str, const(char)* file = __FILE__, int line = __LINE__)
{
	object.vrt_printf("%s:%i error: %s", file, line, str);
	stbi__g_failure_reason = str;
	return 0;
}

alias stbi__uint16 = ushort;
alias stbi__int16  = short;
alias stbi__uint32 = uint;
alias stbi__int32  = int;

struct stbi__context
{
	stbi__uint32 img_x, img_y;
	int img_n, img_out_n;

	stbi_io_callbacks io;
	void *io_user_data;

	int read_from_callbacks;
	int buflen;
	stbi_uc[128] buffer_start;

	stbi_uc* img_buffer, img_buffer_end;
	stbi_uc* img_buffer_original, img_buffer_original_end;
}

void stbi__refill_buffer(stbi__context* s)
{
	int n = s.io.read(s.io_user_data, s.buffer_start.ptr, s.buflen);

	if (n == 0) {
		s.read_from_callbacks = 0;
		s.img_buffer = s.buffer_start.ptr;
		s.img_buffer_end = s.buffer_start.ptr + 1;
		s.img_buffer = null;
	} else {
		s.img_buffer = s.buffer_start.ptr;
		s.img_buffer_end = s.buffer_start.ptr + n;
	}
}

static void stbi__start_mem(stbi__context* s, const(stbi_uc)* buffer, int len)
{
	s.io.read = null;
	s.read_from_callbacks = 0;
	s.img_buffer = s.img_buffer_original = cast(stbi_uc*)buffer;
	s.img_buffer_end = s.img_buffer_original_end = cast(stbi_uc*)buffer + len;
}

static void stbi__start_callbacks(stbi__context* s, stbi_io_callbacks* c, void* user)
{
	s.io = *c;
	s.io_user_data = user;
	s.buflen = cast(int)typeid(typeof(s.buffer_start)).size;
	s.read_from_callbacks = 1;
	s.img_buffer_original = s.buffer_start.ptr;
	stbi__refill_buffer(s);
	s.img_buffer_original_end = s.img_buffer_end;
}

static void stbi__rewind(stbi__context* s)
{
	s.img_buffer = s.img_buffer_original;
	s.img_buffer_end = s.img_buffer_original_end;
}

int stbi__info_main(stbi__context *s, int *x, int *y, int *comp)
{
	if (stbi__bmp_info(s, x, y, comp)) {
		return 1;
	}
	return stbi__err("unknown image type");
}

ubyte* stbi__load_main(stbi__context* s, int* x, int* y, int* comp, int req_comp)
{
	if (stbi__bmp_test(s)) {
		return stbi__bmp_load(s, x, y, comp, req_comp);
	}

	stbi__err("unknown image type");

	return null;
}

ubyte* stbi__load_flip(stbi__context* s, int* x, int* y, int* comp, int req_comp)
{
	ubyte *result = stbi__load_main(s, x, y, comp, req_comp);

	if (stbi__vertically_flip_on_load && result !is null) {
		int w = *x, h = *y;
		int depth = req_comp ? req_comp : *comp;
		int row,col,z;
		stbi_uc temp;


		for (row = 0; row < (h>>1); row++) {
			for (col = 0; col < w; col++) {
				for (z = 0; z < depth; z++) {
					temp = result[(row * w + col) * depth + z];
					result[(row * w + col) * depth + z] = result[((h - row - 1) * w + col) * depth + z];
					result[((h - row - 1) * w + col) * depth + z] = temp;
				}
			}
		}
	}

	return result;
}

stbi_uc* stbi__convert_format(stbi_uc* data, int img_n, int req_comp, uint x, uint y)
{
	int i, j;
	stbi_uc *good;

	if (req_comp == img_n) {
		return data;
	}

	assert(req_comp >= 1 && req_comp <= 4);

	good = cast(stbi_uc*)cMalloc(cast(uint)req_comp * x * y);
	if (good is null) {
		cFree(cast(void*)data);
		stbi__err("outofmem");
		return null;
	}

	for (j = 0; j < cast(int) y; ++j) {
		stbi_uc* src = data + cast(uint)j * x * cast(uint)img_n;
		stbi_uc* dest = good + cast(uint)j * x * cast(uint)req_comp;

		switch (((img_n) * 8 + (req_comp))) {
		case ((1)*8+(2)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 1, dest += 2) {
				dest[0] = src[0]; dest[1] = 255;
			}
			break;
		case ((1)*8+(3)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 1, dest += 3) {
				dest[0] = dest[1] = dest[2] = src[0];
			}
			break;
		case ((1)*8+(4)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 1, dest += 4) {
				dest[0] = dest[1] = dest[2] = src[0];
				dest[3] = 255;
			}
			break;
		case ((2)*8+(1)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 2, dest += 1) {
				dest[0] = src[0];
			}
			break;
		case ((2)*8+(3)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 2, dest += 3) {
				dest[0] = dest[1] = dest[2] = src[0]; 
			}
			break;
		case ((2)*8+(4)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 2, dest += 4) {
				dest[0] = dest[1] = dest[2] = src[0];
				dest[3] = src[1]; 
			}
			break;
		case ((3)*8+(4)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 3, dest += 4) {
				dest[0]=src[0];
				dest[1]=src[1];
				dest[2]=src[2];
				dest[3]=255;
			}
			break;
		case ((3)*8+(1)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 3, dest += 1) {
				dest[0] = stbi__compute_y(src[0], src[1], src[2]);
			}
			break;
		case ((3)*8+(2)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 3, dest += 2) {
				dest[0] = stbi__compute_y(src[0], src[1], src[2]);
				dest[1] = 255;
			}
			break;
		case ((4)*8+(1)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 4, dest += 1) {
				dest[0] = stbi__compute_y(src[0], src[1], src[2]);
			}
			break;
		case ((4)*8+(2)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 4, dest += 2) {
				dest[0] = stbi__compute_y(src[0], src[1], src[2]);
				dest[1] = src[3];
			}
			break;
		case ((4)*8+(3)):
			for (i = cast(int)x - 1; i >= 0; --i, src += 4, dest += 3) {
				dest[0] = src[0];
				dest[1] = src[1];
				dest[2] = src[2];
			}
			break;
		default: 
			assert(false);
		}
	}

	cFree(cast(void*)data);
	return good;
}

stbi_uc stbi__get8(stbi__context *s)
{
	if (cast(size_t)s.img_buffer < cast(size_t)s.img_buffer_end) {
		return *s.img_buffer++;
	}
	if (s.read_from_callbacks) {
		stbi__refill_buffer(s);
		return *(s.img_buffer++);
	}
	return 0;
}

stbi__uint16 stbi__get16le(stbi__context *s)
{
	stbi__uint16 z = stbi__get8(s);
	return cast(stbi__uint16)(z | (stbi__get8(s) << 8u));
}

stbi__uint16 stbi__get16be(stbi__context *s)
{
	stbi__uint16 z = stbi__get8(s);
	return cast(stbi__uint16)((z << 8u) | stbi__get8(s));
}

stbi__uint32 stbi__get32le(stbi__context *s)
{
	stbi__uint32 z = stbi__get16le(s);
	return cast(stbi__uint32)(z | (stbi__get16le(s) << 16u));
}

stbi__uint32 stbi__get32be(stbi__context *s)
{
	stbi__uint32 z = stbi__get16be(s);
	return (z << 16) + stbi__get16be(s);
}

void stbi__skip(stbi__context* s, int n)
{
	if (n < 0) {
		s.img_buffer = s.img_buffer_end;
		return;
	}

	if (s.io.read) {
		int blen = cast(int) (cast(size_t)s.img_buffer_end - cast(size_t)s.img_buffer);
		if (blen < n) {
			s.img_buffer = s.img_buffer_end;
			(s.io.skip)(s.io_user_data, n - blen);
			return;
		}
	}

	s.img_buffer += n;
}

uint stbi__high_bit(uint z)
{
	uint n = 0;
	if (z == 0) {
		return cast(uint)-1;
	}
	if (z >= 0x10000) {
		n += 16; z = z >> 16;
	}
	if (z >= 0x00100) {
		n += 8; z = z >> 8;
	}
	if (z >= 0x00010) {
		n += 4; z = z >> 4;
	}
	if (z >= 0x00004) {
		n += 2; z = z >> 2;
	}
	if (z >= 0x00002) {
		n += 1; z = z >> 1;
	}
	return n;
}

uint stbi__bitcount(uint a)
{
   a = (a & 0x55555555) + ((a >> 1) & 0x55555555);
   a = (a & 0x33333333) + ((a >> 2) & 0x33333333);
   a = (a + (a >> 4)) & 0x0f0f0f0f;
   a = (a + (a >> 8));
   a = (a + (a >> 16));
   return a & 0xff;
}

stbi_uc stbi__compute_y(int r, int g, int b)
{
	return cast(stbi_uc) (((r*77) + (g*150) + (29*b)) >> 8);
}


/*
 *
 * BMP functions.
 *
 */

int stbi__bmp_test(stbi__context* s)
{
	int r = stbi__bmp_test_raw(s);
	stbi__rewind(s);
	return r;
}

int stbi__bmp_test_raw(stbi__context* s)
{
	int r;
	int sz;
	if (stbi__get8(s) != 'B') {
		return 0;
	}

	if (stbi__get8(s) != 'M') {
		return 0;
	}

	stbi__get32le(s);
	stbi__get16le(s);
	stbi__get16le(s);
	stbi__get32le(s);
	sz = cast(int)stbi__get32le(s);
	r = (sz == 12 || sz == 40 || sz == 56 || sz == 108 || sz == 124);
	return r;
}

int stbi__shiftsigned(int v, int shift, int bits)
{
	int result;
	int z=0;

	if (shift < 0) {
		v = v << -shift;
	} else {
		v = v >> shift;
	}
	result = v;

	z = bits;
	while (z < 8) {
		result += v >> z;
		z += bits;
	}
	return result;
}

struct stbi__bmp_data
{
	int bpp, offset, hsz;
	uint mr, mg, mb, ma, all_a;
}

void* stbi__bmp_parse_header(stbi__context *s, stbi__bmp_data *info)
{
	int hsz;
	if (stbi__get8(s) != 'B' || stbi__get8(s) != 'M') {
		stbi__err("not BMP");
		return null;
	}

	stbi__get32le(s);
	stbi__get16le(s);
	stbi__get16le(s);
	info.offset = cast(int)stbi__get32le(s);
	info.hsz = hsz = cast(int)stbi__get32le(s);

	if (hsz != 12 && hsz != 40 && hsz != 56 && hsz != 108 && hsz != 124) {
		stbi__err("unknown BMP");
		return null;
	}

	if (hsz == 12) {
		s.img_x = stbi__get16le(s);
		s.img_y = stbi__get16le(s);
	} else {
		s.img_x = stbi__get32le(s);
		s.img_y = stbi__get32le(s);
	}

	if (stbi__get16le(s) != 1) {
		stbi__err("bad BMP");
		return null;
	}

	info.bpp = stbi__get16le(s);
	if (info.bpp == 1) {
		stbi__err("monochrome");
		return null;
	}

	if (hsz != 12) {
		int compress = cast(int)stbi__get32le(s);
		if (compress == 1 || compress == 2) {
			stbi__err("BMP RLE");
			return null;
		}
		stbi__get32le(s);
		stbi__get32le(s);
		stbi__get32le(s);
		stbi__get32le(s);
		stbi__get32le(s);
		if (hsz == 40 || hsz == 56) {
			if (hsz == 56) {
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
			}
			if (info.bpp == 16 || info.bpp == 32) {
				info.mr = info.mg = info.mb = 0;
				if (compress == 0) {
					if (info.bpp == 32) {
						info.mr = 0xffu << 16;
						info.mg = 0xffu << 8;
						info.mb = 0xffu << 0;
						info.ma = 0xffu << 24;
						info.all_a = 0;
					} else {
						info.mr = 31u << 10;
						info.mg = 31u << 5;
						info.mb = 31u << 0;
					}
				} else if (compress == 3) {
					info.mr = stbi__get32le(s);
					info.mg = stbi__get32le(s);
					info.mb = stbi__get32le(s);

					if (info.mr == info.mg && info.mg == info.mb) {
						stbi__err("bad BMP");
						return null;
					}
				} else {
					stbi__err("bad BMP");
					return null;
				}
			}
		} else {
			int i;
			if (hsz != 108 && hsz != 124) {
				stbi__err("bad BMP");
				return null;
			}
			info.mr = stbi__get32le(s);
			info.mg = stbi__get32le(s);
			info.mb = stbi__get32le(s);
			info.ma = stbi__get32le(s);
			stbi__get32le(s);
			for (i=0; i < 12; ++i) {
				stbi__get32le(s);
			}
			if (hsz == 124) {
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
				stbi__get32le(s);
			}
		}
	}

	return cast(void *)1;
}

int stbi__bmp_info(stbi__context* s, int* x, int* y, int* comp)
{
	void *p;
	stbi__bmp_data info;

	info.all_a = 255;
	p = stbi__bmp_parse_header(s, &info);
	stbi__rewind( s );
	if (p is null) {
		return 0;
	}
	*x = cast(int)s.img_x;
	*y = cast(int)s.img_y;
	*comp = info.ma ? 4 : 3;
	return 1;
}

stbi_uc* stbi__bmp_load(stbi__context *s, int *x, int *y, int *comp, int req_comp)
{
	stbi_uc *out_;
	uint mr = 0, mg = 0, mb = 0, ma = 0, all_a;
	stbi_uc[4][256] pal;
	int psize = 0, i , j, width;
	int flip_vertically, pad, target;
	stbi__bmp_data info;

	info.all_a = 255;
	if (stbi__bmp_parse_header(s, &info) is null) {
		return null;
	}

	flip_vertically = (cast(int) s.img_y) > 0;
	s.img_y = cast(uint)(cast(int)s.img_y < 0 ? -cast(int)s.img_y : cast(int)s.img_y);

	mr = info.mr;
	mg = info.mg;
	mb = info.mb;
	ma = info.ma;
	all_a = info.all_a;

	if (info.hsz == 12) {
		if (info.bpp < 24) {
			psize = (info.offset - 14 - 24) / 3;
		}
	} else {
		if (info.bpp < 16) {
			psize = (info.offset - 14 - info.hsz) >> 2;
		}
	}

	s.img_n = ma ? 4 : 3;
	if (req_comp && req_comp >= 3) {
		target = req_comp;
	} else {
		target = s.img_n;
	}

	out_ = cast(stbi_uc*) cMalloc(cast(uint)target * s.img_x * s.img_y);

	if (out_ is null) {
		stbi__err("outofmem");
		return null;
	}

	if (info.bpp < 16) {
		int z = 0;
		if (psize == 0 || psize > 256) {
			cFree(cast(void*)out_);
			stbi__err("invalid");
			return null;
		}

		for (i=0; i < psize; ++i) {
			pal[i][2] = stbi__get8(s);
			pal[i][1] = stbi__get8(s);
			pal[i][0] = stbi__get8(s);
			if (info.hsz != 12) stbi__get8(s);
			pal[i][3] = 255;
		}
		stbi__skip(s, info.offset - 14 - info.hsz - psize * (info.hsz == 12 ? 3 : 4));
		if (info.bpp == 4) {
			width = cast(int)((s.img_x + 1u) >> 1u);
		} else if (info.bpp == 8) {
			width = cast(int)s.img_x;
		} else {
			cFree(cast(void*)out_);
			stbi__err("bad bpp");
			return null;
		}

		pad = (-width) & 3;
		for (j=0; j < cast(int) s.img_y; ++j) {
			for (i=0; i < cast(int) s.img_x; i += 2) {
				int v=stbi__get8(s),v2=0;
				if (info.bpp == 4) {
					v2 = v & 15;
					v = v >> 4;
				}
				out_[z++] = pal[v][0];
				out_[z++] = pal[v][1];
				out_[z++] = pal[v][2];
				if (target == 4) {
					out_[z++] = 255;
				}
				if (i+1 == cast(int)s.img_x) {
					break;
				}
				v = (info.bpp == 8) ? stbi__get8(s) : cast(stbi_uc)v2;
				out_[z++] = pal[v][0];
				out_[z++] = pal[v][1];
				out_[z++] = pal[v][2];
				if (target == 4) {
					out_[z++] = 255;
				}
			}
			stbi__skip(s, pad);
		}

	} else {
		int rshift = 0, gshift = 0, bshift = 0, ashift = 0, rcount = 0, gcount = 0, bcount = 0, acount = 0;
		int z = 0;
		int easy = 0;
		stbi__skip(s, info.offset - 14 - info.hsz);
		if (info.bpp == 24) {
			width = cast(int)(3u * s.img_x);
		} else if (info.bpp == 16) {
			width = cast(int)(2u * s.img_x);
		} else {
			width = 0;
		}
		pad = (-width) & 3;
		if (info.bpp == 24) {
			easy = 1;
		} else if (info.bpp == 32) {
			if (mb == 0xff && mg == cast(uint)0xff00 && mr == cast(uint)0x00ff0000 && ma == cast(uint)0xff000000) {
				easy = 2;
			}
		}
		if (!easy) {
			if (!mr || !mg || !mb) {
				cFree(cast(void*)out_);
				stbi__err("bad masks");
			}

			rshift = cast(int)(stbi__high_bit(mr) - 7); rcount = cast(int)stbi__bitcount(mr);
			gshift = cast(int)(stbi__high_bit(mg) - 7); gcount = cast(int)stbi__bitcount(mg);
			bshift = cast(int)(stbi__high_bit(mb) - 7); bcount = cast(int)stbi__bitcount(mb);
			ashift = cast(int)(stbi__high_bit(ma) - 7); acount = cast(int)stbi__bitcount(ma);
		}

		for (j=0; j < cast(int) s.img_y; ++j) {
			if (easy) {
				for (i=0; i < cast(int) s.img_x; ++i) {
					stbi_uc a;
					out_[z+2] = stbi__get8(s);
					out_[z+1] = stbi__get8(s);
					out_[z+0] = stbi__get8(s);
					z += 3;
					a = (easy == 2 ? stbi__get8(s) : 255);
					all_a |= a;
					if (target == 4) {
						out_[z++] = a;
					}
				}
			} else {
				int bpp = info.bpp;
				for (i=0; i < cast(int) s.img_x; ++i) {
					stbi__uint32 v = (bpp == 16 ? cast(stbi__uint32) stbi__get16le(s) : stbi__get32le(s));
					int a;
					out_[z++] = (cast(stbi_uc) ((stbi__shiftsigned(cast(int)(v & mr), rshift, rcount)) & 255));
					out_[z++] = (cast(stbi_uc) ((stbi__shiftsigned(cast(int)(v & mg), gshift, gcount)) & 255));
					out_[z++] = (cast(stbi_uc) ((stbi__shiftsigned(cast(int)(v & mb), bshift, bcount)) & 255));
					a = (ma ? stbi__shiftsigned(cast(int)(v & ma), ashift, acount) : 255);
					all_a |= cast(uint)a;
					if (target == 4) {
						out_[z++] = (cast(stbi_uc) ((a) & 255));
					}
				}
			}
			stbi__skip(s, pad);
		}
	}


	if (target == 4 && all_a == 0) {
		for (i = cast(int)(4 * s.img_x * s.img_y - 1); i >= 0; i -= 4) {
			out_[i] = 255;
		}
	}

	if (flip_vertically) {
		stbi_uc t;
		for (j=0; j < cast(int) s.img_y>>1; ++j) {
			stbi_uc *p1 = out_ + j * cast(int)s.img_x * target;
			stbi_uc *p2 = out_ + (cast(int)s.img_y-1-j)*cast(int)s.img_x*target;
			for (i=0; i < cast(int) s.img_x*target; ++i) {
				t = p1[i];
				p1[i] = p2[i];
				p2[i] = t;
			}
		}
	}

	// Make sure we return the actual of the resulting image.
	int result_comp = target;

	if (req_comp && req_comp != target) {
		// Update comp.
		result_comp = req_comp;
		out_ = stbi__convert_format(out_, target, req_comp, s.img_x, s.img_y);
		if (out_ is null) {
			return out_;
		}
	}

	*x = cast(int)s.img_x;
	*y = cast(int)s.img_y;
	if (comp) {
		*comp = result_comp;
	}
	return out_;
}
