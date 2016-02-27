// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/**
 * Source file for c memory alloction functions.
 */
module charge.sys.memory;

debug {

	extern(C) {
		size_t cMemoryUsage();

		void* cMalloc(size_t size,
		              const(char)* file = __FILE__,
		              uint line = __LINE__);

		void* cRealloc(void *ptr, size_t size,
		               const(char)* file = __FILE__,
		               uint line = __LINE__);

		void cFree(void *ptr,
		           char* file = __FILE__,
		           uint line = __LINE__);
	}

} else {

	public import core.stdc.stdlib :
		cMalloc = malloc,
		cRealloc = realloc,
		cFree = free;

}
