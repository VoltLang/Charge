// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for Resource and Pool.
 */
module charge.sys.resource;

import core.typeinfo;

import watt.text.sink : Sink;
import watt.text.format : format;

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
	mNext: Resource;
	mPrev: Resource;
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


private:
	fn insert(ref root: Resource)
	{
		if (root !is null) {
			root.mPrev = this;
			mNext = root;
		}
		root = this;
	}

	fn remove(ref root: Resource)
	{
		if (root is this) {
			root = mNext;
		}
		if (mPrev !is null) {
			mPrev.mNext = mNext;
		}
		if (mNext !is null) {
			mNext.mPrev = mPrev;
		}

		mPrev = null;
		mNext = null;
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
	global mInstance: Pool;

	mAlive: Resource;
	mMarked: Resource;


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
		while (mMarked !is null) {
			r := mMarked;
			r.remove(ref mMarked);
			r.__dtor();
			cFree(cast(void*)r);
		}
	}

	fn cleanAndLeakCheck(sink: Sink)
	{
		collect();

		r := mAlive;
		while (r !is null) {
			format(sink, "%s not collected\n", r.url);
			r = r.mNext;
		}
	}


private:
	final fn mark(r: Resource)
	{
		r.remove(ref mAlive);
		r.insert(ref mMarked);
	}

	final fn resource(r: Resource)
	{
		r.insert(ref mAlive);
	}
}
