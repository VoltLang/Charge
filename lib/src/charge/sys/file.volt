// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for Resource and Pool.
 */
module charge.sys.file;

import core.exception;
import core.c.stdio;

import watt.conv;
import watt.text.format;

import charge.sys.memory;
import charge.sys.resource;


/*!
 * Dereference and reference helper function.
 *
 * @param dec Object to dereference passed by reference, set to `inc`.
 * @param inc Object to reference.
 * @{
 */
fn reference(ref dec: File, inc: File)
{
	if (inc !is null) { inc.incRef(); }
	if (dec !is null) { dec.decRef(); }
	dec = inc;
}
//! @}

/*!
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
	ptr: immutable(void)*;


public:
	@property fn data() immutable(void)[]
	{
		return ptr[0 .. size];
	}

	/*!
	 * A file that is created from `import("filename.txt")` import expressions.
	 */
	global fn fromImport(filename: string, data: immutable(void)[]) File
	{
		dummy: void*;
		raw := Resource.alloc(typeid(File), uri, filename, 0, out dummy);

		file := cast(File)raw;
		file.__ctor(data.ptr, data.length);

		return file;
	}

	/*!
	 * Same as above, accepts string as that is what ´import("file")´ returns;.
	 */
	global fn fromImport(filename: string, data: string) File
	{
		return fromImport(filename, cast(immutable(void)[])data);
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
		file.__ctor(cast(immutable(void)*) ptr, size);

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

	this(ptr: immutable(void)*, size: size_t)
	{
		this.ptr = ptr;
		this.size = size;

		super();
	}
}
