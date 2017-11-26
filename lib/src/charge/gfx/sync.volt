// Copyright © 2012-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/*!
 * Source file for syncing with the gpu.
 */
module charge.gfx.sync;

import lib.gl.gl33;

import charge.gfx.gl;


/*!
 * Sync object.
 *
 * Prefix already added.
 */
struct Sync
{
private:
	obj: GLsync;


public:
	/*!
	 * Insert a sync object into the GPU command stream.
	 */
	local fn insert() Sync
	{
		sync: Sync;
		sync.obj = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

		return sync;
	}

	/*!
	 * Sync with the gpu and delete sync object or timeout happens, in milliseconds.
	 */
	fn waitAndDelete(ref sync: Sync, timeout: i64) bool
	{
		if (sync.obj is null) {
			return true;
		}

		auto tm = timeout * 1000 * 1000;
		if (tm < 0) {
			tm = 0;
		}

		auto ret = glClientWaitSync(sync.obj, GL_SYNC_FLUSH_COMMANDS_BIT, cast(u64)tm);

		switch(ret) {
		case GL_ALREADY_SIGNALED:
		case GL_CONDITION_SATISFIED:
			glDeleteSync(sync.obj);
			sync.obj = null;
			return true;
		case GL_WAIT_FAILED:
			glCheckError("gfxSyncWait");
			return false;
		default:
			return false;
		}
	}

	/*!
	 * Delete a sync object.
	 */
	fn close(ref sync: Sync)
	{
		if (sync.obj !is null) {
			glDeleteSync(sync.obj);
		}
		sync.obj = null;
	}
}
