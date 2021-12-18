// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for c memory alloction functions.
 */
module charge.sys.memory;

debug {

	extern(C) {
		fn cMemoryUsage() size_t;

		fn cMalloc(size: size_t,
		           file: const(char)* = __FILE__,
		           line: uint = __LINE__)  void*;

		fn cRealloc(ptr: void*, size: size_t,
		            file: const(char)* = __FILE__,
		            line: uint = __LINE__)  void*;

		fn cFree(ptr: void*,
		         file: const(char)* = __FILE__,
		         line: uint = __LINE__)  void;
	}

} else {

	public import core.c.stdlib :
		cMalloc = malloc,
		cRealloc = realloc,
		cFree = free;

	fn cMemoryUsage() size_t
	{
		return 0;
	}

}
