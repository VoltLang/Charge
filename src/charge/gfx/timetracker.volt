// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
/*!
 * Source file for TimeTrackers and trackers.
 */
module charge.gfx.timetracker;

import watt.text.sink : Sink;
import watt.text.format : format;

import math = charge.math;

import charge.gfx.gl;


final class TimeTracker
{
public:
	name: string;
	samples: math.Average;
	last: GLuint64;


private:
	global gTracker: Tracker;


public:
	this(name: string)
	{
		if (gTracker is null) {
			gTracker = new Tracker();
		}

		this.name = name;
	}

	global fn getLastFrame(sink: Sink)
	{
		if (gTracker is null) {
			gTracker = new Tracker();
		}

		gTracker.getLastFrame(sink);
	}

	fn startFrame()
	{
		gTracker.startFrame(this);
	}

	fn endFrame()
	{
		gTracker.endFrame(this);
	}

	fn start()
	{
		gTracker.push(this);
	}

	fn exchange()
	{
		gTracker.exchange(this);
	}

	fn stop()
	{
		gTracker.pop(this);
	}
}


private:

final class Entry
{
private:
	mNext: Entry;
	mId: GLuint;

	mStop: TimeTracker;
	mStart: TimeTracker;
	mRunning: bool;
	mLast: GLuint64;


private:
	this()
	{
		glCreateQueries(GL_TIMESTAMP, 1, &mId);
	}

	fn close()
	{
		if (mId != 0) {
			glDeleteQueries(1, &mId);
			mId = 0;
		}
	}

	fn reset()
	{
		mStart = null;
		mStop = null;
	}

	fn add()
	{
		glQueryCounter(mId, GL_TIMESTAMP);
		mRunning = true;
	}

	fn get(out val: GLuint64)
	{
		if (mRunning) {
			glGetQueryObjectui64v(mId, GL_QUERY_RESULT, &mLast);
			mRunning = false;
		}
		val = mLast;
	}
}

final class Tracker
{
private:
	mRoot: Entry;
	mPool: Entry;
	mFrame: Entry;
	mLastFrame: Entry;


private:
	fn getLastFrame(sink: Sink)
	{
		numRunning: u32;

		e := mLastFrame;
		mLastFrame = null;

		lastStarted: TimeTracker;

		while(e !is null) {
			val: GLuint64;
			e.get(out val);

			if (stop := e.mStop) {
				elapsed := val - stop.last;
				stop.last = elapsed;
				stop.samples.add(elapsed);

				if (lastStarted is stop) {
					sink.printIndent(numRunning);
					sink.printTimeTracker(stop);
				} else {
					numRunning--;
					sink.printIndent(numRunning);
					sink.printMS(stop);
					sink(" sum\n");
				}
				lastStarted = null;
			}

			if (start := e.mStart) {
				start.last = val;

				if (lastStarted !is null) {
					sink.printIndent(numRunning);
					format(sink, "%s\n", lastStarted.name);
					numRunning++;
				}

				lastStarted = start;
			}

			tmp := e;
			e = e.mNext;
			putEntry(tmp);
		}
	}


	fn startFrame(t: TimeTracker)
	{
		assert(mFrame is null);

		e := getEntry();
		e.add();
		e.mStart = t;

		mFrame = e;
		mRoot = e;
	}

	fn endFrame(t: TimeTracker)
	{
		assert(mRoot !is null);
		assert(mFrame !is null);
		assert(mFrame.mStart is t);

		pop(t);

		mLastFrame = mFrame;
		mFrame = null;
		mRoot = null;
	}

	fn push(t: TimeTracker)
	{
		assert(mRoot !is null);
		assert(mFrame !is null);

		e := getEntry();
		e.add();
		e.mStart = t;

		mRoot.mNext = e;
		mRoot = e;
	}

	fn pop(t: TimeTracker)
	{
		assert(mRoot !is null);
		assert(mFrame !is null);

		e := getEntry();
		e.add();
		e.mStop = t;

		mRoot.mNext = e;
		mRoot = e;
	}

	fn exchange(t: TimeTracker)
	{
		e := getEntry();
		e.add();
		e.mStart = t;
		e.mStop = mRoot.mStart;

		mRoot.mNext = e;
		mRoot = e;
	}

	fn getEntry() Entry
	{
		if (mPool is null) {
			return new Entry();
		}

		e := mPool;
		mPool = e.mNext;
		e.mNext = null;
		return e;
	}

	fn putEntry(e: Entry)
	{
		e.reset();
		e.mNext = mPool;
		mPool = e;
	}
}

fn printIndent(sink: Sink, numRunning: u32)
{
	foreach (0u .. numRunning) {
		sink("   ");
	}
}

fn printMS(sink: Sink, t: TimeTracker)
{
	elapsed := t.samples.calc();
	elapsed /= (1_000_000_000u / 1_000_000u);

	format(sink, "-% 2s.%03sms", elapsed / 1000, elapsed % 1000);
}

fn printTimeTracker(sink: Sink, t: TimeTracker)
{
	sink.printMS(t);
	format(sink, " %s\n", t.name);
}
