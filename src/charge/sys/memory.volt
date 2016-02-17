// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver 1.0).
/**
 * Source file for c memory alloction functions.
 */
module charge.sys.memory;

debug {

	extern(C) {
		@mangledName("charge_usage")
		size_t cMemoryUsage();

		@mangledName("charge_malloc")
		void* cMalloc(size_t size,
		              const(char)* file = __FILE__,
		              uint line = __LINE__);

		@mangledName("charge_realloc")
		void* cRealloc(void *ptr, size_t size,
		               const(char)* file = __FILE__,
		               uint line = __LINE__);

		@mangledName("charge_free")
		void cFree(void *ptr,
		           char* file = __FILE__,
		           uint line = __LINE__);
	}

} else {
	import core.stdc.stdlib :
		cMalloc = malloc,
		cRealloc = realloc,
		cFree = free;

	size_t cMemoryUsage()
	{
		return 0;
	}
}
