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

/* $Header: g:/library/wwlib32/file/rcs/loadpict.cpp 1.1 1994/04/20 14:38:08 scott_bowen Exp $ */
/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood Library                         *
 *                                                                         *
 *                    File Name : IFFEXTRA.C                               *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : June 11, 1991                            *
 *                                                                         *
 *                  Last Update : April 20, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   ILBM_To_Amiga -- Convert ILBM to bitplane Amiga format.               *
 *   ILBM_To_MCGA -- Converts ILBM picture into MCGA format.               *
 *   PBM_To_Amiga -- Converts a PBM picture into Amiga format.             *
 *   Load_Picture -- Loads a picture file (CPS or LBM format).             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <wwstd.h>
#include "iff.h"
#include "file.h"
#include <video.h>	// For GraphicMode and MCGA_MODE.
#include <wwmem.h>	// For Alloc.

#if(IBM)
#include <mem.h>
#endif

// Since we are not currently using AMIGA, this has been put in to 
// give us back some code space.  If it is needed for a utility,
// this module should be recompiled with that utility and set the
// define to TRUE.
#define	MAKE_AMIGA_ART	FALSE

/*
** An IFF picture file can have one of two formats:
**	ILBM	- InterLeaved Bit Map
**	PBM	- Packed Bit Map
*/
typedef enum {
	FORM_ILBM,
	FORM_PBM
} IFFForm_Type;

/*
**	These are the various chunks that compose an IFF picture file.
*/
#define ID_FORM			MAKE_ID('F','O','R','M')
#define ID_ILBM			MAKE_ID('I','L','B','M')
#define ID_PBM 			MAKE_ID('P','B','M',' ')
#define ID_CMAP 			MAKE_ID('C','M','A','P')
#define ID_BODY 			MAKE_ID('B','O','D','Y')
#define ID_BMHD 			MAKE_ID('B','M','H','D')


/*
**	The BMHD (Bit Map HeaDer) chunk in an IFF picture file contains the
**	information necessary to extract that picture from the BODY chunk.
**	It also indicates the size and depth of the source art.
*/
typedef struct {
	UWORD	W, H;				// Raster width and height in pixels.
	WORD 	X, Y;				// Pixel postion for this image.
	BYTE	BPlanes;			// Number of bitplanes.
	UBYTE	Masking;			// Masking control byte.
								// 0 = No masking.
								//	1 = Has a mask.
								//	2 = Has transparent color.
								//	3 = Lasso.
	UBYTE	Compression;	// Compression method.
								// 0 = No compression.
								// 1 = Byte run compression.
	BYTE	pad;
	UWORD	Transparent;	// Transparent color number.
	UBYTE	XAspect,			// Pixel aspect ratio of source art.
			YAspect;
	WORD	PageWidth, 		// Source 'page' size in pixels.
			PageHeight;
} BitMapHeader_Type;

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/

PRIVATE VOID cdecl ILBM_To_MCGA(BufferClass& src, BufferClass& dest, WORD planes);
PRIVATE VOID cdecl ILBM_To_Amiga(BufferClass& src, BufferClass& dest, WORD planes);
PRIVATE VOID cdecl PBM_To_Amiga(BufferClass& src, BufferClass& dest, WORD planes);


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/



/***************************************************************************
 * ILBM_TO_MCGA -- Converts ILBM picture into MCGA format.                 *
 *                                                                         *
 *    This converts an ILBM picture (typical of DPaint LBM files) and      *
 *    converts it to MCGA mode (byte per pixel).  This function would be   *
 *    used after the body of an ILBM picture is loaded.  Because the       *
 *    number of bitplanes can vary greatly, it is necessary to pass the    *
 *    bitplane count to this function.  The size (320 by 200) of the       *
 *    source picture is presumed.                                          *
 *                                                                         *
 * INPUT:   src   - Buffer number for source ILBM picture.                 *
 *                                                                         *
 *          dest  - Buffer number for place to put MCGA format.            *
 *                                                                         *
 *          planes- The number of bitplanes in the ILBM picture.           *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/16/1991 JLB : Created.                                             *
 *   04/20/1994 SKB : Update to 32 bit library and make private.           *
 *=========================================================================*/
PRIVATE VOID cdecl ILBM_To_MCGA(BufferClass& src, BufferClass& dest, WORD planes)
{
	BYTE	*source;			// Source pointer.
	BYTE	*destination;	// Destination pointer.
	WORD	index,j,i;		// Working index values.
	WORD	bplane;			// Bit plane counter.
	BYTE	bytes[8];		// Byte array holding max bitplanes (8).
	BYTE	value;			// Composed byte(pixel) value.

	source = (BYTE *) src.Get_Buffer();
	destination = (BYTE *) dest.Get_Buffer();

	memset(bytes, '\0', 8);	// Makes sure upper bits will be clear.

	// Each row is grouped and processed together.

	for (index = 0; index < 200 /*bmhd.H*/; index++) {

		// Process each line in groups of 8 bytes.

		for (j = 0; j < 40 /*(bmhd.W>>3)*/; j++) {

			// Get the bitplane bytes.

			for (bplane = 0; bplane < planes /*bmhd.BPlanes*/; bplane++) {
				bytes[bplane] = *(source + (bplane * 40 /*(bmhd.W>>3)*/));
			}
			source++;

			// Roll the bits out to create 8 pixels (by bytes).
			for (i = 0; i < 8; i++) {

				// 8 bits per byte.
				value = 0;
				for (bplane = planes - 1/*bmhd.BPlanes-1*/; bplane >= 0; bplane--) {
					value <<= 1;			// Make room for next bit.
					if (bytes[bplane] & 0x80) value |= 1;	// Set the bit.
					bytes[bplane] <<= 1;
				}
				*destination++ = value;	// Output the pixel byte.
			}
		}

		// Advance to next scan line.
		source += 40 /* (bmhd.W >> 3)*/ * (planes /* bmhd.BPlanes */ - 1);
	}
}


/***************************************************************************
 * ILBM_TO_AMIGA -- Convert ILBM to bitplane Amiga format.                 *
 *                                                                         *
 *    This converts an InterLeaved BitMap picture into Amiga bitplane      *
 *    format (8K per bitplane).  The data of an ILBM picture is controlled *
 *    by the number of bitplanes it contains.  The bitplane count is       *
 *    passed into this program.                                            *
 *                                                                         *
 * INPUT:   src   - Buffer number for source ILBM picture data.            *
 *                                                                         *
 *          dest  - Buffer number for destination Amiga picture data.      *
 *                                                                         *
 *          planes- The number of bitplanes in the source ILBM data.       *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   The amount of data placed into the destination buffer is    *
 *             controlled by the number of bitplanes specified.  It is     *
 *             8000 per bitplane.                                          *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/20/1991 JLB : Created.                                             *
 *   04/20/1994 SKB : Update to 32 bit library and make private.           *
 *   04/20/1994 SKB : #if out for main library.  Only used in utils maybe. *
 *=========================================================================*/
#if MAKE_AMIGA_ART
PRIVATE VOID cdecl ILBM_To_Amiga(BufferClass& src, BufferClass& dest, WORD planes)
{
	WORD	row;			// Working row counter.
	WORD	bp;			// Working bitplane counter.
	BYTE	*srcptr,		// Source buffer pointer.
			*dstptr;		// Destination buffer pointer.

	srcptr = (BYTE *) src.Get_Buffer();		// Source buffer pointer.
	dstptr = (BYTE *) dest.Get_Buffer();	// Destination buffer pointer.

	for (row = 0; row < 200; row++) {
		for (bp = 0; bp < planes; bp++) {
			Mem_Copy(srcptr,dstptr+(8000*bp),40);
			srcptr += 40;
		}
		dstptr += 40;
	}
}
#endif


/***************************************************************************
 * PBM_TO_AMIGA -- Converts a PBM picture into Amiga format.               *
 *                                                                         *
 *    This converts a PBM (Packed Bit Map) MCGA picture into Amiga         *
 *    bitplane format.  A PBM picture presumes 8 bitplanes, but this       *
 *    can be controlled by the 'plane' parameter passed in.                *
 *                                                                         *
 * INPUT:   src   - Buffer number for the source PBM data.                 *
 *                                                                         *
 *          dest  - Buffer number to place the Amiga format picture.       *
 *                                                                         *
 *          planes- The number of bitplanes to extract from the PBM source *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   The amount of data placed into the destination buffer is    *
 *             controlled by the number of bitplanes specified.  It is     *
 *             8000 per bitplane.                                          *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/20/1991 JLB : Created.                                             *
 *   04/20/1994 SKB : Update to 32 bit library and make private.           *
 *   04/20/1994 SKB : #if out for main library.  Only used in utils maybe. *
 *=========================================================================*/
#if MAKE_AMIGA_ART
PRIVATE VOID cdecl PBM_To_Amiga(BufferClass& src, BufferClass& dest, WORD planes)
{
	WORD	row,				// Working row counter.
			col,				// Working column (by byte) counter.
			bit;				// Working bitplane counter.
	UBYTE	*destptr,		// Destination byte pointer.
			*srcptr;			// Source byte pointer.
	UBYTE	value;			// Working input MCGA pixel number.


	destptr = (UBYTE *) dest.Get_Buffer();
	srcptr = (UBYTE *) src.Get_Buffer();

	memset(destptr, 0, 32000);
	memset(destptr+32000, 0, 32000);

	for (row = 0; row < 200; row++) {
		
		for (col = 0; col < 320; col++) {
			value = *srcptr++;

			for (bit = 0; bit < planes; bit++) {
				if (value & (0x01 << bit)) {
					destptr[(WORD)((8000L * (LONG)bit) + (col>>3))] |= 0x80 >> (col & 0x07);
				}
			}
		}
		
		destptr += 40;
	}
}
#endif


#ifdef NEVER
/***************************************************************************
 * LOAD_PICTURE -- Loads a picture file (CPS or LBM format).               *
 *                                                                         *
 *    This loads a picture file into a page buffer.  The loaded file will  *
 *    be in MCGA or Amiga mode as requested.  Supported source formats     *
 *    are CPS or all forms of IFF dpaint files.                            *
 *                                                                         *
 * INPUT:   filename    - Source filename.  The only files that are        *
 *                        processed as IFF are those files that end with   *
 *                        ".LBM".                                          *
 *                                                                         *
 *          loadbuf     - Buffer type number for the temporary loading     *
 *                        buffer.  It will be trashed.                     *
 *                                                                         *
 *          destbuf     - Buffer type number for the picture to be placed. *
 *                                                                         *
 *          palette     - Palette buffer pointer.  If this value is NULL   *
 *                        then no palette is loaded.                       *
 *                                                                         *
 *          format      - Desired destination format.                      *
 *                      BM_AMIGA - Destination buffer will contain the     *
 *                                 picture in bitplane format (Amiga).     *
 *                                 The buffer will contain data equal to   *
 *                                 8K times the number of bit planes.      *
 *                                                                         *
 *                      BM_MCGA  - Destination buffer will contain the     *
 *                                 picture in MCGA format (byte per pixel).*
 *                                 The buffer will be 64K in size.         *
 *                                                                         *
 * OUTPUT:  WORD number of bitplanes read into the dest buffer					*
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/16/1991 JLB : Created.                                             *
 *   05/20/1991 JLB : Handles Amiga and IBM destination formats.           *
 *=========================================================================*/
WORD cdecl Load_Picture(BYTE const *filename, BufferClass& scratchbuf, BufferClass& destbuf, UBYTE *palette, PicturePlaneType format)
{
	int	fh;						// Input file handle.
	long	ifftype;					// Iff form type.
	int	counter;					// Count of the bytes decompressed.
	int	value;					// Working compression code value.
	int	len;						// WORD sized length value.
	int	index;					// Working index values.
	BitMapHeader_Type	bmhd;		// BMHD chunk data.
	IFFForm_Type	   formtype; // ILBM, PBM.
	char	*src;						 // Working source body pointer.
	char	*dest;					 // Working destination body pointer.


	//len = strlen(filename);
	//strupr(filename);

	fh = Open_File(filename,READ);
	if (fh == ERROR) return(FALSE);
	Read_File(fh,&ifftype,4L);
	Close_File(fh);

	if (ifftype != ID_FORM) 
	{
		UBYTE * ptr = NULL ;

		if ( GraphicMode == MCGA_MODE || 
           ( GraphicMode >= VESA_MIN && GraphicMode <= VESA_MAX ) )
			  													 ptr = palette ;

//		return((WORD)Load_Uncompress(filename, scratchbuf, destbuf, (GraphicMode == MCGA_MODE) ? palette : NULL) / 8000);
		return((WORD)Load_Uncompress(filename, scratchbuf, destbuf,  palette ) / 8000 ) ;
	} 
	else 
	{

		fh = Open_Iff_File(filename);	// Opens and checks for IFF form.
		if (fh == ERROR) return(FALSE);

		Read_File(fh, &ifftype, 4L);
		if (ifftype == ID_ILBM) {
			formtype = FORM_ILBM;				// Inter-Leaved Bit Map.
		} else {
			if (ifftype == ID_PBM) {
				formtype = FORM_PBM;			// Packed Bit Map.
			} else {
				return FALSE;				// Not a recognizable picture file.
			}
		}

		// Load the BMHD chunk.
		if (Read_Iff_Chunk(fh,ID_BMHD,(BYTE*)&bmhd,sizeof(BitMapHeader_Type))) {

			#if(IBM)
				// Perform necessary IBM conversions to the data.
				bmhd.W = Reverse_WORD(bmhd.W);
				bmhd.H = Reverse_WORD(bmhd.H);
				bmhd.X = Reverse_WORD(bmhd.X);
				bmhd.Y = Reverse_WORD(bmhd.Y);

				// this is a mistake Xaspect and YAspect are char type
				// bmhd.XAspect = Reverse_WORD(bmhd.XAspect);
				// bmhd.YAspect = Reverse_WORD(bmhd.YAspect);
				  value = bmhd.XAspect	;
				  bmhd.XAspect = bmhd.YAspect ;
				  bmhd.YAspect = ( unsigned char ) value ;
				  				
				bmhd.PageWidth = Reverse_WORD(bmhd.PageWidth);
				bmhd.PageHeight = Reverse_WORD(bmhd.PageHeight);
			#endif

			if (bmhd.Masking > 2) return FALSE;			// Don't allow brushes.
			if (bmhd.Compression > 1) return FALSE;	// Unknown compression.

		} else {
			return FALSE;				// Unable to read the required BMHD chunk.
		}

		// Load the palette if asked.
		if (palette) 
		{
			int	pbytes ;			       	// Number of CMAP bytes required.
			unsigned char	color;			// Palette color value.
			unsigned char *paletteptr;		// Allocated buffer for palette conversions.
			unsigned char *source;		  	// Scratch source CMAP data pointer.
			unsigned char *dest2;		  	// Scratch destination palette pointer.

			//	Number of CMAP bytes that are needed.
			pbytes = (1 << bmhd.BPlanes) * 3;

			// Allocate the temporary palette buffer.
			paletteptr = (UBYTE *)Alloc(pbytes, MEM_CLEAR);
			source = paletteptr;
			dest2 = palette;

			//	Read in only the bytes that are needed.
			pbytes = (WORD)Read_Iff_Chunk(fh, ID_CMAP, (BYTE *) paletteptr, pbytes);

#if(IBM)
			if ( pbytes && 
              ( ( GraphicMode >= VESA_MIN && GraphicMode <= VESA_MAX ) ||
			         GraphicMode == MCGA_MODE ) ) 
		  {
#else
			if (pbytes) {
#endif

				/*
				** CMAP to machine specific palette conversion code.  Conversion
				**	goes from CMAP three bytes per color register to the machine
				**	specific form.
				*/
				switch(format) {
					default:
					case BM_MCGA:
						// Convert CMAP to IBM MCGA palette form.
						for (index = 0; index < pbytes; index++) {
							*dest2++ = *source++ >> 2;
						}
						break;
#if MAKE_AMIGA_ART

					case BM_AMIGA:
						// Convert CMAP to Amiga nibble packed palette form.
						for (index = 0; index < pbytes; index += 3) {
							*dest2++   = *(source++) >> 4;
							color 	 = (*(source++) & 0xf0);
							color 	+= *(source++) >> 4;
							*dest2++	 = color;
						}

						break;
#endif
				}
			}

			Free(paletteptr);
		}


		//	Load in BODY chunk.
		dest = (BYTE *) scratchbuf.Get_Buffer();
		src  = (BYTE *) destbuf.Get_Buffer();

		if (Read_Iff_Chunk(fh, ID_BODY, src, destbuf.Get_Size())) 
		{
			for (index = 0; index < (WORD)bmhd.H; index++) 
			{	
			   /* Height of source */
				//	Transfer (possibly uncompress) one row of data.
				// PBM or ILBM reader. Bytes per row (all bitplanes).

				counter = bmhd.BPlanes * (bmhd.W >> 3);

				//	If there is a mask then there is one more bitplane.
				if (bmhd.Masking == 1) 	
											counter += bmhd.W >> 3 ;

				if (bmhd.Compression == 1) 
				{	
				   // The data is compressed.
					//	Decompress one scanline (all bitplanes) at a time.
					while (counter) 
					{
						value = ( signed char ) *src++; 			// Decompression code.
						if (value == -128) continue;	// NOOP code.

						if (value >= 0) 
						{		
							// Copy N+1 bytes.
							len = ((WORD) value) + 1;

							//	Ignore the masking bitplane.
							if ( bmhd.Masking != 1 || 
							     (bmhd.Masking==1 && counter > ((WORD)bmhd.W >> 3) ) ) 
							{
								memcpy(dest, src, len);
								dest += len;
							}
							counter -= len;
							src += len;

						} 
						else 
						{
							// Replicate -N+1 bytes.
							len = (-((WORD) value)) + 1;
							value = *src++;
							
							//	Ignore the masking bitplane.
							if (bmhd.Masking != 1 || (bmhd.Masking==1 && counter > ((WORD)bmhd.W >> 3))) 
							{
								memset(dest,value,len);
								dest += len;
							}
							counter -= len;
						}
					}
				} 

				else 
				{
				   // Plain data is just copied.
					memcpy(dest,src,counter);
					dest += counter;
					src += counter;
				}
			}

			/*
			**	Perform necessary conversions to the data in order to reach 
			**	the desired format.
			*/
			switch (format) {
				default:
				case BM_MCGA:			// Byte per pixel desired.
					if (formtype == FORM_ILBM) {
						ILBM_To_MCGA(scratchbuf, destbuf, bmhd.BPlanes);
					} else {
						Mem_Copy(scratchbuf.Get_Buffer(), destbuf.Get_Buffer(), 64000L);
					}
					break;
				
#if MAKE_AMIGA_ART
				case BM_AMIGA:			// Bitplane format desired.
					if (formtype == FORM_ILBM) {
						ILBM_To_Amiga(scratchbuf, destbuf, bmhd.BPlanes);
					} else {
						PBM_To_Amiga(scratchbuf, destbuf, bmhd.BPlanes);
					}
					break;
#endif
			}
		}

		Close_Iff_File(fh);
	}
			
	return((WORD)bmhd.BPlanes);			// Loaded the picture successfully.
}
#endif
