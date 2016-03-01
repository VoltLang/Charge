// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Resource and Pool.
 */
module charge.sys.file;

import watt.text.format;

import core.stdc.stdio;
import charge.sys.memory;
import charge.sys.resource;


/**
 * A single File from the file system or a zip file.
 *
 * Right now very stupid.
 *
 * @ingroup Resource
 */
class File : Resource
{
public:
	enum string uri = "file://";

	size_t size;
	void* ptr;

public:
	@property void[] data()
	{
		return ptr[0 .. size];
	}

	global File load(string filename)
	{
		void* ptr;
		FILE* fp;
		size_t size;


		loadFile(filename, out fp, out size);

		void* raw = Resource.alloc(typeid(File), uri, filename, size, out ptr);
		
		size_t bytesRead = fread(ptr, 1, size, fp);
		if (bytesRead != size) {
			cFree(raw);
			fclose(fp);
			throw new Exception("read failure.");
		}
		fclose(fp);

		auto file = cast(File)raw;
		file.__ctor(ptr, size);
		
		return file;
	}


protected:
	global void loadFile(string filename, out FILE* fp, out size_t size)
	{
		auto cstr = filename ~ "\0";

		fp = fopen(cstr.ptr, "rb");
		if (fp is null) {
			throw new Exception(format("Couldn't open file '%s' for reading.", filename));
		}

		if (fseek(fp, 0, SEEK_END) != 0) {
			fclose(fp);
			throw new Exception("fseek failure.");
		}

		size = cast(size_t) ftell(fp);
		if (size == cast(size_t) -1) {
			fclose(fp);
			throw new Exception("ftell failure.");
		}

		if (fseek(fp, 0, SEEK_SET) != 0) {
			fclose(fp);
			throw new Exception("fseek failure.");
		}
	}

	global void read(FILE* fp, void* ptr, size_t size)
	{
		size_t bytesRead = fread(ptr, 1, size, fp);
		if (bytesRead != size) {
			fclose(fp);
			throw new Exception("read failure.");
		}
	}

	this(void* ptr, size_t size)
	{
		this.ptr = ptr;
		this.size = size;

		super();
	}
}
