// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for Resource and Pool.
 */
module charge.sys.resource;

import core.typeinfo;

import charge.sys.memory;


/*!
 * Reference base class for all Resources.
 *
 * @ingroup Resource
 */
abstract class Resource
{
public:
	url: string;
	name: string;


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
	                out extraPtr: void*,
	                file: const(char)* = __FILE__,
	                line: uint = __LINE__) void*
	{
		sz := ti.classSize + uri.length + name.length + extraSize;
		debug {
			ptr := cMalloc(sz, file, line);
		} else {
			ptr := cMalloc(sz);
		}

		startClass: size_t = 0;
		endClass: size_t = ti.classSize;
		ptr[startClass .. endClass] = ti.classInit[startClass .. endClass];

		uriStart := endClass;
		uriEnd := uriStart + uri.length;
		ptr[uriStart .. uriEnd] = cast(void[])uri;

		nameStart := uriEnd;
		nameEnd := nameStart + name.length;
		ptr[nameStart .. nameEnd] = cast(void[])name;

		if (extraSize > 0) {
			extraPtr = ptr + nameEnd;
		}

		r := cast(Resource)ptr;
		r.url = cast(string)ptr[uriStart .. nameEnd];
		r.name = cast(string)ptr[nameStart .. nameEnd];

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


/*!
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
