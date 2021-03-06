// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Source file for timers.
 *
 * @ingroup gfx
 */
module charge.gfx.timer;

import lib.gl.gl33;

import charge.gfx.gl;


struct Timer
{
private:
	mLast: GLuint64;
	mId: GLuint;
	mStarted: bool;
	mStopped: bool;


public:
	fn setup()
	{
		glGenQueries(1, &mId);
	}

	fn close()
	{
		if (mId) { glDeleteQueries(1, &mId); mId = 0; }
	}

	fn start()
	{
		dummy: GLuint64;
		if (mStarted || mStopped) {
			return;
		}
		glBeginQuery(GL_TIME_ELAPSED, mId);
		mStarted = true;
	}

	fn stop()
	{
		if (!mStarted) {
			return;
		}
		glEndQuery(GL_TIME_ELAPSED);
		mStarted = false;
		mStopped = true;
	}

	fn getValue(out val: GLuint64) bool
	{
		val = mLast;
		if (!mStopped) {
			return false;
		}

		available: GLint;
		glGetQueryObjectiv(mId, GL_QUERY_RESULT_AVAILABLE, &available);
		if (!available) {
			return false;
		}

		glGetQueryObjectui64v(mId, GL_QUERY_RESULT, &mLast);
		mStopped = false;
		val = mLast;
		return true;
	}
}
