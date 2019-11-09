// Copyright 2011-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for BasicCore.
 *
 * @ingroup core
 */
module charge.core.basic;

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

	logicDg: dg();
	closeDg: dg();
	renderDg: dg();
	idleDg: dg(long);


public:
	override fn setIdle(dgt: dg(long)) {
		if (dgt is null) {
			idleDg = defaultIdle;
		} else {
			idleDg = dgt;
		}
	}

	override fn setRender(dgt: dg()) {
		if (dgt is null) {
			renderDg = defaultDg;
		} else {
			renderDg = dgt;
		}
	}

	override fn setLogic(dgt: dg()) {
		if (dgt is null) {
			logicDg = defaultDg;
		} else {
			logicDg = dgt;
		}
	}

	override fn setClose(dgt: dg()) {
		if (dgt is null) {
			closeDg = defaultDg;
		} else {
			closeDg = dgt;
		}
	}


protected:
	this(flags: Flag)
	{
		super(flags);

		setRender(null);
		setLogic(null);
		setClose(null);
		setIdle(null);

		gInstance = this;
	}


private:
	final fn defaultIdle(long)
	{
		// This method intentionally left empty.
	}

	final fn defaultDg()
	{
		// This method intentionally left empty.
	}
}
