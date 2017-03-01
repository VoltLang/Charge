// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Resource and Pool.
 */
module charge.sys.file;

import core.exception;
import core.c.stdio;

import watt.conv;
import watt.text.format;

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

	size: size_t;
	ptr: void*;


public:
	@property fn data() void[]
	{
		return ptr[0 .. size];
	}

	global fn load(filename: string) File
	{
		ptr: void*;
		fp: FILE*;
		size: size_t;


		loadFile(filename, out fp, out size);

		raw := Resource.alloc(typeid(File), uri, filename, size, out ptr);
		
		bytesRead := fread(ptr, 1, size, fp);
		if (bytesRead != size) {
			cFree(raw);
			fclose(fp);
			throw new Exception("read failure.");
		}
		fclose(fp);

		file := cast(File)raw;
		file.__ctor(ptr, size);
		
		return file;
	}


protected:
	global fn loadFile(filename: string, out fp: FILE*, out size: size_t)
	{
		cstr := filename.toStringz();

		fp = fopen(cstr, "rb");
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

	global fn read(fp: FILE*, ptr: void*, size: size_t)
	{
		bytesRead := fread(ptr, 1, size, fp);
		if (bytesRead != size) {
			fclose(fp);
			throw new Exception("read failure.");
		}
	}

	this(ptr: void*, size: size_t)
	{
		this.ptr = ptr;
		this.size = size;

		super();
	}
}
