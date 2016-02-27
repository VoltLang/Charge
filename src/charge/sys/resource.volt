// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Resource and Pool.
 */
module charge.sys.resource;

import charge.sys.memory;


/**
 * Reference base class for all Resources.
 *
 * @ingroup Resource
 */
abstract class Resource
{
public:
	string url;

private:
	int mRefcount;

protected:
	this()
	{
		this.mRefcount = 1;

		Pool.opCall();
		Pool.mInstance.resource(this);
	}

	abstract void collect();

	global void* alloc(object.TypeInfo ti,
	                   scope const(char)[] uri,
	                   scope const(char)[] name,
	                   size_t extraSize,
	                   out void* extraPtr)
	{
		size_t sz = ti.classSize + uri.length + name.length + extraSize;
		void* ptr = cMalloc(sz);

		size_t start = 0;
		size_t end = ti.classSize;
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

		auto r = cast(Resource)ptr;
		r.url = cast(string)ptr[ti.classSize .. end];

		return ptr;
	}

private:
	final void incRef()
	{
		if (mRefcount++ == 0) {
			assert(false);
		}

		assert(mRefcount > 0);
	}

	final void decRef()
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
	bool suppress404;

private:
	Resource[] mMarked;

	global Pool mInstance;

public:
	this()
	{
	}

	global Pool opCall()
	{
		if (mInstance is null) {
			mInstance = new Pool();
		}
		return mInstance;
	}

	void collect()
	{
		foreach (r; mMarked) {
			r.collect();
			cFree(cast(void*)r);
		}
		mMarked = null;
	}

	void clean()
	{
		collect();
	}


private:
	final void mark(Resource r)
	{
		mMarked ~= r;
	}

	final void resource(Resource r)
	{
	}
}
