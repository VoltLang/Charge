// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/*!
 * Source file for c memory allocation and tracking functions.
 */
module charge.sys.memheader;

static import core.c.stdlib;
static import core.c.string;

import core.rt.format;

import watt.text.sink : Sink;
import watt.text.format : format;


extern(C) fn cMemoryUsage() size_t
{
	return MemHeader.gMemory;
}

extern(C) fn cMemoryPrintAll(sink: Sink)
{
	if (MemHeader.gMemory == 0 && MemHeader.gRoot is null) {
		return;
	}

	h := MemHeader.gRoot;
	while (h !is null) {
		format(sink, "%s:%s error: leaked ", h.file, h.line);
		vrt_format_readable_size(sink, h.size);
		sink("\n");
		h = h.mNext;
	}

	sink("total leakage ");
	vrt_format_readable_size(sink, MemHeader.gMemory);
	sink("\n");
}

debug {

	extern(C) fn cMalloc(size: size_t, file: const(char)*, line: u32) void*
	{
		totalSize := size + typeid(MemHeader).size;

		mem := cast(MemHeader*)core.c.stdlib.malloc(totalSize);
		mem.mNext = null;
		mem.mPrev = null;
		mem.setup(size, file, line);

		return mem.data;
	}

	extern(C) fn cRealloc(ptr: void*, size: size_t, file: const(char)*, line: u32) void*
	{
		totalSize := size + typeid(MemHeader).size;

		if (ptr is null && size == 0) {
			return null;
		}

		if (ptr is null) {
			return cMalloc(size, file, line);
		}

		if (size == 0) {
			cFree(ptr, file, line);
			return null;
		}

		mem := MemHeader.fromData(ptr);
		mem.close();

		mem = cast(MemHeader*)core.c.stdlib.realloc(
				cast(void*)mem, totalSize);

		mem.setup(size, file, line);
		return mem.data;
	}

	extern(C) fn cFree(ptr: void*, file: const(char)*, line: u32)
	{
		if (ptr is null) {
			return;
		}

		mem := MemHeader.fromData(ptr);
		mem.close();

		core.c.stdlib.free(cast(void*)mem);
	}

} else {

	extern(C) fn cMalloc(size: size_t, file: const(char)*, line: u32) void*
	{
		return core.c.stdlib.malloc(size);
	}

	extern(C) fn cRealloc(ptr: void*, size: size_t, file: const(char)*, line: u32) void*
	{
		return core.c.stdlib.realloc(ptr, size);
	}

	extern(C) fn cFree(ptr: void*, file: const(char)*, line: u32)
	{
		core.c.stdlib.free(ptr);
	}

}

private struct MemHeader
{
private:
	global gMemory: size_t;
	global gRoot: MemHeader*;

	mSize: size_t;
	mNext: MemHeader*;
	mPrev: MemHeader*;

	mFile: const(char)*;
	mLine: u32;

	mMagic: u32;


public:
	@property fn data() void* { return cast(void*)(&this + 1); }
	@property fn size() size_t { return mSize; }
	@property fn line() u32 { return mLine; }

	@property fn file() const(char)[]
	{
		if (mFile is null) {
			return null;
		}
		return mFile[0 .. core.c.string.strlen(mFile)];
	}

	fn setup(size: size_t, file: const(char)*, line: uint)
	{
		this.mFile = file;
		this.mLine = line;
		this.mSize = size;
		this.mMagic = 0;

		assert(mPrev is null);
		assert(mNext is null);

		gMemory += size;
		if (gRoot !is null) {
			gRoot.mPrev = &this;
			mNext = gRoot;
		}
		gRoot = &this;
	}

	fn close()
	{
		if (gRoot is &this) {
			gRoot = mNext;
		}
		if (mPrev !is null) {
			mPrev.mNext = mNext;
		}
		if (mNext !is null) {
			mNext.mPrev = mPrev;
		}

		// Update accounting.
		gMemory -= mSize;

		// Zero out memory.
		mSize = 0;
		mNext = null;
		mPrev = null;
		mFile = null;
		mLine = 0;
		mMagic = 0;
	}

	global fn fromData(ptr: void*) MemHeader*
	{
		if (ptr is null) {
			return null;
		}
		return cast(MemHeader*)ptr - 1;
	}
}
