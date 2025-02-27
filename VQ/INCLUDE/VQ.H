/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef VQ_H
#define VQ_H
/****************************************************************************
*
*        C O N F I D E N T I A L ---  W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* NAME
*     vq.h
*
* DESCRIPTION
*     Vq file definition
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
****************************************************************************/

/* VQHeader - VQ header structure.
 *
 * ImageSize       - Compressed image size 
 * ImageWidth      - Image x-dimension
 * ImageHeight     - Image y-dimension
 * BlockWidth      - Block x-dimension
 * BlockHeight     - Block y-dimension
 * BlockType       - Block type
 * PaletteRange    - Number of palette colors
 * Num1Color       - Number of 1-color blocks & 1-color colors
 * CodebookSize    - Number of actual codebook entries
 * CodingFlag      - Flag for 2-color blocks
 * FrameDiffMethod - Frame differencing method
 * ForcedPalette   - Force a palette on image
 * F555Palette     - Flag for output 15-bit palette
 * VQVersion       - VQ Version #
 * pad[5]          - Pad out to 40 bytes total
 */
typedef struct _VQHeader {
	unsigned long  ImageSize;
	unsigned short ImageWidth;
	unsigned short ImageHeight;
	unsigned short BlockWidth;
	unsigned short BlockHeight;
	unsigned short BlockType;
	unsigned short PaletteRange;
	unsigned short Num1Color;
	unsigned short CodebookSize;
	unsigned short CodingFlag;
	unsigned short FrameDiffMethod;
	unsigned short ForcedPalette;
	unsigned short F555Palette;
	unsigned short VQVersion;
	unsigned short pad[5];
} VQHeader;

#endif /* VQ_H */
