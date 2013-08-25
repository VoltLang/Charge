// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.loader;


alias Loader = void* delegate(string);

version(Windows) {

	import std.c.windows.windows;

} else {

	// XXX Proper way to import this.
	extern(C)
	{
		void *dlopen(const(char)* file, int mode);
		int dlclose(void* handle);
		void *dlsym(void* handle, const(char)* name);
		char* dlerror();
	}

	enum RTLD_NOW    = 0x00002;
	enum RTLD_GLOBAL = 0x00100;

}

class Library
{
public:
	global Library loads(string[] files)
	{
		for (size_t i; i < files.length; i++) {
			auto l = load(files[i]);
			if (l !is null) {
				return l;
			}
		}

		return null;
	}

	version (Windows) {

		global Library load(string filename)
		{
			void *ptr = LoadLibraryA(filename.ptr);

			if (ptr is null) {
				return null;
			}

			return new Library(ptr);
		}

		void* symbol(string symbol)
		{
			return GetProcAddress(cast(HANDLE)ptr, symbol.ptr);
		}

		~this()
		{
			if (ptr !is null) {
				FreeLibrary(cast(HANDLE)ptr);
			}
			return;
		}

	} else version (Linux) {


		global Library load(string filename)
		{
			void *ptr = dlopen(filename.ptr, RTLD_NOW | RTLD_GLOBAL);

			if (ptr is null) {
				return null;
			}

			return new Library(ptr);
		}

		void* symbol(string symbol)
		{
			return dlsym(ptr, symbol.ptr);
		}

		~this()
		{
			if (ptr !is null) {
				dlclose(ptr);
				ptr = null;
			}
			return;
		}

	} else version (Darwin) {

		global Library load(string filename)
		{
			void *ptr = dlopen(toStringz(filename), RTLD_NOW | RTLD_GLOBAL);

			if (ptr is null) {
				return null;
			}

			return new Library(ptr);
		}

		void* symbol(string symbol)
		{
			return dlsym(ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr !is null) {
				dlclose(ptr);
				ptr = null;
			}
			return;
		}

	} else {

		global Library load(string filename)
		{
			throw new Exception("Huh oh! no impementation");
		}

		void* symbol(string symbol)
		{
			throw new Exception("Huh oh! no impementation");
		}

	}

private:
	this(void *ptr) { this.ptr = ptr; return; }
	void *ptr;

}
