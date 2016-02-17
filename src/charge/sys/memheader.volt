// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver 1.0).
/**
 * Source file for c memory allocation and tracking functions.
 */
module charge.sys.memheader;

static import core.stdc.stdlib;


private struct MemHeader
{
private:
	size_t size;
	const(char)* file;
	uint line;
	uint magic;

	global size_t memory;

public:
	static MemHeader* fromData(void *ptr)
	{
		if (ptr is null) {
			return null;
		}
		return cast(MemHeader*)ptr - 1;
	}

	void* getData()
	{
		return cast(void*)(cast(MemHeader*)&this + 1);
	}
}

extern(C):

size_t charge_usage()
{
	return MemHeader.memory;
}

void* charge_malloc(size_t size, const(char)* file, uint line)
{
	size_t totalSize = size + typeid(MemHeader).size;
	MemHeader* mem = cast(MemHeader*)core.stdc.stdlib.malloc(totalSize);

	mem.file = file;
	mem.line = line;
	mem.size = size;

	MemHeader.memory += size;
	return mem.getData();
}

void* charge_realloc(void* ptr, size_t size, const(char)* file, uint line)
{
	size_t totalSize = size + typeid(MemHeader).size;

	if (ptr is null && size == 0) {
		return null;
	}

	if (ptr is null) {
		return charge_malloc(size, file, line);
	}

	if (size == 0) {
		charge_free(ptr, file, line);
		return null;
	}

	auto mem = MemHeader.fromData(ptr);
	MemHeader.memory -= mem.size;

	mem = cast(MemHeader*)core.stdc.stdlib.realloc(
		cast(void*)mem, totalSize);

	mem.file = file;
	mem.line = line;
	mem.size = size;

	MemHeader.memory += mem.size;
	return mem.getData();
}

void charge_free(void* ptr, const(char)* file, uint line)
{
	auto mem = MemHeader.fromData(ptr);

	MemHeader.memory -= mem.size;
	core.stdc.stdlib.free(cast(void*)mem);
}
