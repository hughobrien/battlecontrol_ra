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

/* $Header: /CounterStrike/WRITEPCX.CPP 1     3/03/97 10:26a Joe_bostic $ */
/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : iff                                      *
 *                                                                         *
 *                    File Name : WRITEPCX.CPP                             *
 *                                                                         *
 *                   Programmer : Julio R. Jerez                           *
 *                                                                         *
 *                   Start Date : May 2, 1995                              *
 *                                                                         *
 *                  Last Update : May 2, 1995   [JRJ]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * int Save_PCX_File (char* name, GraphicViewPortClass& pic, char* palette)*
 *= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

#include	"function.h"
#include "pcx.h"


static void Write_Pcx_ScanLine(FileClass & file, int scansize, char * ptr);


/***************************************************************************
 * WRITE_PCX_FILE -- Write the data in ViewPort to a pcx file              *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:  name is a NULL terminated string of the format [xxxx.pcx]			*
 *			  pic	 is a pointer to a GraphicViewPortClass or to a 				*
 *					 GraphicBufferClass holding the picture. 							*
 *        palette is a pointer the the memory block holding the color 		*
 *              palette of the picture.                                    *
 *                                                                         *
 * OUTPUT: FALSE  if the function fails zero otherwise             			*
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/04/1995 JRJ : Created.                                             *
 *   08/01/1995 SKB : Copy the palette so it is not modified.              *
 *   06/03/1996 JLB : Converted to C++ and file class I/O.                 *
 *=========================================================================*/

static const unsigned char rle_code = 0xC0;					// Run code.
static const unsigned char rle_max_run = 0x2F;				// Maximum run allowed.
static const unsigned char rle_full_run = (rle_max_run|rle_code);	// Full character run.


/***********************************************************************************************
 * Write_PCX_File -- Write a PCX file from specified buffer.                                   *
 *                                                                                             *
 *    This routine will take the specified buffer and write out the data as a PCX file to the  *
 *    the file object specified.                                                               *
 *                                                                                             *
 * INPUT:   file     -- Reference to the file object to write the buffer as a PCX file.        *
 *                                                                                             *
 *          pic      -- Reference to a graphic buffer that contains the data to be written.    *
 *                                                                                             *
 *          palette  -- Reference to the palette to be attached to the PCX file as well.       *
 *                                                                                             *
 * OUTPUT:  bool; Was there an error?                                                          *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/03/1996 JLB : Created.                                                                 *
 *=============================================================================================*/
int Write_PCX_File(FileClass & file, GraphicBufferClass & pic, PaletteClass * palette)
{
 	unsigned char palcopy[256 * sizeof(RGB)];
	int	VP_Scan_Line;
	char	* ptr;
	RGB	* pal;
	PCX_HEADER header = {
		10,
		5,
		1,
		8,
		0,
		0,
		(short)(pic.Get_Width()-1),
		(short)(pic.Get_Height()-1),
		(short)(pic.Get_Width()),
		(short)(pic.Get_Height()),
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		0,
		1,
		(short)pic.Get_Width(),
		1,
		{0}
	};

	/*
	**	Open the output file and write out the header information. If the file
	**	is already open, then just presume that it is positioned correctly and is
	**	open for write.
	*/
	bool open = false;
	if (!file.Is_Open()) {
		file.Open(WRITE);
		open = true;
	}
	file.Write(&header, sizeof(header));

	/*
	**	Write out the picture, line by line.
	*/
	VP_Scan_Line = pic.Get_Width() + pic.Get_XAdd();
	ptr = (char *)pic.Get_Buffer() ;
	ptr += ((pic.Get_YPos() * VP_Scan_Line) + pic.Get_XPos());
	for (int line = 0; line < header.height + 1; line++) {
   	Write_Pcx_ScanLine(file, header.byte_per_line, ptr + line * VP_Scan_Line ) ;
	}

	/*
	**	Special marker for end of RLE data.
	*/
	unsigned char ender = 0x0C;
	file.Write(&ender, sizeof(ender));

	/*
	**	Convert the palette from 6 bit to 8 bit format.
	*/
	memmove(palcopy, palette, sizeof(PaletteClass));
	pal = (RGB *)palcopy ;
	for (int palindex = 0; palindex < 256; palindex++) {
		pal->red = (unsigned char)((pal->red<<2)); // | (pal->red>>6));
		pal->green = (unsigned char)((pal->green<<2)); // | (pal->green>>6));
		pal->blue = (unsigned char)((pal->blue<<2)); // | (pal->blue>>6));
		pal++;
	}

	/*
	**	Write the palette out.
	*/
	file.Write(palcopy, sizeof(palcopy));

	/*
	**	Close the file (if necessary) and exit with no error flag.
	*/
	if (open) {
		file.Close();
	}
	return(false);
}


/***********************************************************************************************
 * Write_Pcx_ScanLine -- Writes a PCX scanline.                                                *
 *                                                                                             *
 *    Writes out a PCX scanline using RLE compression.                                         *
 *                                                                                             *
 * INPUT:   file     -- Reference to the file to write the scan line to.                       *
 *                                                                                             *
 *          scansize -- The number of bytes to compress (write).                               *
 *                                                                                             *
 *          ptr      -- Pointer to the data to compress (write).                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/04/1995 JRJ : Created.                                                                 *
 *   06/03/1996 JLB : Converted to C++ and file class I/O.                                     *
 *=============================================================================================*/
static void Write_Pcx_ScanLine(FileClass & file, int scansize, char * ptr)
{
	unsigned char last = *ptr;
	unsigned char rle=1;
	unsigned char c;
	for (int i = 1; i < scansize; i++) {
   	unsigned char color = (unsigned char)(0xff & * ++ptr);
		if (color == last) {
			rle++;
			if (rle == rle_max_run) {
				file.Write(&rle_full_run, sizeof(rle_full_run));
				file.Write(&color, sizeof(color));
				rle = 0 ;
			}
		} else {
	  		if (rle) {
		 		if (rle == 1 && (rle_code != (rle_code & last))) {
			   	file.Write(&last, sizeof(last));
		     	} else {
					c = (unsigned char)(rle | rle_code);
		      	file.Write(&c, sizeof(c));
	     	   	file.Write(&last, sizeof(last));
				}
			}
			last = color ;
			rle = 1 ;
		}
	}
	if (rle) {
		if (rle == 1 && ( rle_code != (rle_code & last))) {
			file.Write(&last, sizeof(last));
		} else {
			c = (unsigned char)(rle | rle_code);
			file.Write(&c, sizeof(c));
	   	file.Write(&last, sizeof(last));
		}
	}
}

