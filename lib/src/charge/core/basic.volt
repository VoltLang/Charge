// Copyright 2011-2019, Jakob Bornecrantz.
// Copyright 2019-2022, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for BasicCore.
 *
 * @ingroup core
 */
module charge.core.basic;

import gfx = charge.gfx;
import charge.core;


@mangledName("chargeGet") fn get() Core
{
	return BasicCore.gInstance;
}

/*!
 * More basic helper core that only implements dg functions.
 */
abstract class BasicCore : Core
{
protected:
	global gInstance: BasicCore;

	mRetVal: int;

	closeDg: dg();
	updateActionsDg: dg(i64);
	logicDg: dg();
	renderViewDg: dg(gfx.Target, ref gfx.ViewInfo);
	idleDg: dg(long);


public:
	override fn setClose(dgt: dg()) {
		if (dgt is null) {
			closeDg = defaultDg;
		} else {
			closeDg = dgt;
		}
	}

	override fn setUpdateActions(dgt: dg(i64)) {
		if (dgt is null) {
			updateActionsDg = defaultDgI64;
		} else {
			updateActionsDg = dgt;
		}
	}

	override fn setLogic(dgt: dg()) {
		if (dgt is null) {
			logicDg = defaultDg;
		} else {
			logicDg = dgt;
		}
	}

	override fn setRenderView(dgt: dg(gfx.Target, ref gfx.ViewInfo)) {
		if (dgt is null) {
			renderViewDg = defaultDgRenderView;
		} else {
			renderViewDg = dgt;
		}
	}

	override fn setIdle(dgt: dg(i64)) {
		if (dgt is null) {
			idleDg = defaultDgI64;
		} else {
			idleDg = dgt;
		}
	}


protected:
	this(flags: Flag)
	{
		super(flags);

		setClose(null);
		setUpdateActions(null);
		setLogic(null);
		setRenderView(null);
		setIdle(null);

		gInstance = this;
	}


private:
	final fn defaultDgRenderView(gfx.Target, ref gfx.ViewInfo)
	{
		// This method intentionally left empty.
	}

	final fn defaultDgI64(i64)
	{
		// This method intentionally left empty.
	}

	final fn defaultDg()
	{
		// This method intentionally left empty.
	}
}
