// Copyright 2016-2019, Jakob Bornecrantz.
// SPDX-License-Identifier: BSL-1.0
module voxel.svo.design;

import math = charge.math;


/*!
 * Some constants used troughout the code.
 * @{
 */
enum NumDim = 3;

enum XShift = 0;
enum YShift = 1;
enum ZShift = 2;
/*!
 * @}
 */

/*!
 * Constants used in the rendering pipeline.
 * @{
 */
enum BufferNum = 6;
enum u32 BufferCommandId = BufferNum; // Buffer ids start at zero.
/*!
 * @}
 */

/*!
 * Information about a single SVO, used by loaders and the pipeline.
 */
struct Create
{
	isAMD: bool;
}
