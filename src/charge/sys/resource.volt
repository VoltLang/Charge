// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Resource and Pool.
 */
module charge.sys.resource;

import core.typeinfo;

import charge.sys.memory;


/**
 * Reference base class for all Resources.
 *
 * @ingroup Resource
 */
abstract class Resource
{
public:
	url: string;

private:
	mRefcount: int;

protected:
	this()
	{
		this.mRefcount = 1;

		Pool.opCall();
		Pool.mInstance.resource(this);
	}

	global fn alloc(ti: TypeInfo,
	                uri: scope const(char)[],
	                name: scope const(char)[],
	                extraSize: size_t,
	                out extraPtr: void*) void*
	{
		sz: size_t = ti.classSize + uri.length + name.length + extraSize;
		ptr: void* = cMalloc(sz);

		start: size_t = 0;
		end: size_t = ti.classSize;
		ptr[start .. end] = ti.classInit[start .. end];

		start = end;
		end = start + uri.length;
		ptr[start .. end] = cast(void[])uri;

		start = end;
		end = start + name.length;
		ptr[start .. end] = cast(void[])name;

		if (extraSize > 0) {
			extraPtr = ptr + end;
		}

		r := cast(Resource)ptr;
		r.url = cast(string)ptr[ti.classSize .. end];

		return ptr;
	}

public:
	final fn incRef()
	{
		if (mRefcount++ == 0) {
			assert(false);
		}

		assert(mRefcount > 0);
	}

	final fn decRef()
	{
		assert(mRefcount > 0);

		mRefcount--;
		if (mRefcount == 0) {
			Pool.mInstance.mark(this);
		}
	}
}


/**
 * Pool for named resources.
 *
 * @ingroup Resource
 */
class Pool
{
public:
	suppress404: bool;


private:
	mMarked: Resource[];

	global mInstance: Pool;


public:
	this()
	{
	}

	global fn opCall() Pool
	{
		if (mInstance is null) {
			mInstance = new Pool();
		}
		return mInstance;
	}

	fn collect()
	{
		foreach (r; mMarked) {
			r.__dtor();
			cFree(cast(void*)r);
		}
		mMarked = null;
	}

	fn clean()
	{
		collect();
	}


private:
	final fn mark(r: Resource)
	{
		mMarked ~= r;
	}

	final fn resource(r: Resource)
	{
	}
}
