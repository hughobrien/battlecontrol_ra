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

/* $Header: /CounterStrike/KEYFRAME.CPP 1     3/03/97 10:25a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : KEYFRAME.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                   Programmer : David Dettmer                                                *
 *                                                                                             *
 *                   Start Date : 06/25/95                                                     *
 *                                                                                             *
 *                  Last Update : June 25, 1995 [JLB]                                          *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   Get_Build_Frame_Count -- Fetches the number of frames in data block.                      *
 *   Get_Build_Frame_Width -- Fetches the width of the shape image.                            *
 *   Get_Build_Frame_Height -- Fetches the height of the shape image.                          *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#include "function.h"

#define SUBFRAMEOFFS			7	// 3 1/2 frame offsets loaded (2 offsets/frame)


#define	Apply_Delta(buffer, delta)		Apply_XOR_Delta((char*)(buffer), (char*)(delta))

typedef struct {
	unsigned short frames;
	unsigned short x;
	unsigned short y;
	unsigned short width;
	unsigned short height;
	unsigned short largest_frame_size;
	short				flags;
} KeyFrameHeaderType;



#ifdef WIN32
#define	INITIAL_BIG_SHAPE_BUFFER_SIZE	20000000
#define	UNCOMPRESS_MAGIC_NUMBER			56789

unsigned	BigShapeBufferLength = INITIAL_BIG_SHAPE_BUFFER_SIZE;
extern "C"{
	char		* BigShapeBufferStart = NULL;
	BOOL		UseBigShapeBuffer = FALSE;
}
char		* BigShapeBufferPtr = NULL;
int			TotalBigShapes=0;
BOOL		ReallocShapeBufferFlag = FALSE;



char	** KeyFrameSlots [1000];
int 	TotalSlotsUsed=0;



typedef struct tShapeHeaderType{
	unsigned draw_flags;
	char		* shape_data;
} ShapeHeaderType;

static int Length;

void * Get_Shape_Header_Data(void * ptr)
{
	if (UseBigShapeBuffer) {
		return((void *)(((ShapeHeaderType *)ptr)->shape_data+(long)BigShapeBufferStart));
	} else {
		return (ptr);
	}
}

int Get_Last_Frame_Length(void)
{
	return(Length);
}



void Reallocate_Big_Shape_Buffer(void)
{
	if (ReallocShapeBufferFlag) {
		BigShapeBufferLength += 2000000;							//Extra 2 Mb of uncompressed shape space
		BigShapeBufferPtr -= (unsigned)BigShapeBufferStart;
		BigShapeBufferStart = (char*)Resize_Alloc(BigShapeBufferStart, BigShapeBufferLength);
		BigShapeBufferPtr += (unsigned)BigShapeBufferStart;
		ReallocShapeBufferFlag = FALSE;
	}
}




void Check_Use_Compressed_Shapes (void)
{
	MEMORYSTATUS	mem_info;

	mem_info.dwLength=sizeof(mem_info);
	GlobalMemoryStatus(&mem_info);

	UseBigShapeBuffer = (mem_info.dwTotalPhys > 12*1024*1024) ? TRUE : FALSE;
}

#endif


unsigned long Build_Frame(void const * dataptr, unsigned short framenumber, void * buffptr)
{
#ifdef FIXIT_SCORE_CRASH
	char * ptr;
	unsigned long offcurr, offdiff;
#else
	char * ptr, * lockptr;
	unsigned long offcurr, off16, offdiff;
#endif
	unsigned long offset[SUBFRAMEOFFS];
	KeyFrameHeaderType * keyfr;
	unsigned short buffsize, currframe, subframe;
	unsigned long length = 0;
	char frameflags;

	//
	// valid pointer??
	//
	if ( !dataptr || !buffptr ) {
		return(0);
	}

	//
	// look at header then check that frame to build is not greater
	// than total frames
	//
	keyfr = (KeyFrameHeaderType *) dataptr;

	if ( framenumber >= keyfr->frames ) {
		return(0);
	}

	// calc buff size
	buffsize = keyfr->width * keyfr->height;

	// get offset into data
	ptr = (char *)dataptr + (((unsigned long)framenumber << 3) + sizeof(KeyFrameHeaderType));
	Mem_Copy( ptr, &offset[0], 12L );
	frameflags = (char)(offset[0] >> 24);

	if ( (frameflags & KF_KEYFRAME) ) {

		ptr = (char *)Add_Long_To_Pointer( dataptr, (offset[0] & 0x00FFFFFFL) );

		if (keyfr->flags & 1 ) {
			ptr = (char *)Add_Long_To_Pointer( ptr, 768L );
		}

		length = LCW_Uncompress( ptr, buffptr, buffsize );
	} else {	// key delta or delta

		if ( (frameflags & KF_DELTA) ) {
			currframe = (unsigned short)offset[1];

			ptr = (char *)Add_Long_To_Pointer( dataptr, (((unsigned long)currframe << 3) + sizeof(KeyFrameHeaderType)) );
			Mem_Copy( ptr, &offset[0], (long)(SUBFRAMEOFFS * sizeof(unsigned long)) );
		}

		// key frame
		offcurr = offset[1] & 0x00FFFFFFL;

		// key delta
		offdiff = (offset[0] & 0x00FFFFFFL) - offcurr;

		ptr = (char *)Add_Long_To_Pointer( dataptr, offcurr );

		if (keyfr->flags & 1 ) {
			ptr = (char *)Add_Long_To_Pointer( ptr, 768L );
		}

#ifndef FIXIT_SCORE_CRASH
		off16 = (unsigned long)lockptr & 0x00003FFFL;
#endif

		length = LCW_Uncompress( ptr, buffptr, buffsize );

		if (length > buffsize) {
			return(0);
		}

#ifndef FIXIT_SCORE_CRASH
		if ( ((offset[2] & 0x00FFFFFFL) - offcurr) >= (0x00010000L - off16) ) {

			ptr = (char *)Add_Long_To_Pointer( ptr, offdiff );
			off16 = (unsigned long)ptr & 0x00003FFFL;

			offcurr += offdiff;
			offdiff = 0;
		}
#endif

#ifdef NEVER
		// check for LCW'd rsd

		if ( ((offset[1] >> 24) & KF_LCW) ) {
			length = LCW_Uncompress( ptr, buffptr, buffsize );
		} else {
			length = buffsize;
			Apply_XOR_Delta( buffptr, Add_Long_To_Pointer( ptr, offdiff ) );
		}
#else
		length = buffsize;
		Apply_Delta(buffptr, Add_Long_To_Pointer(ptr, offdiff));
#endif

		if ( (frameflags & KF_DELTA) ) {
			// adjust to delta after the keydelta

			currframe++;
			subframe = 2;

			while (currframe <= framenumber) {
				offdiff = (offset[subframe] & 0x00FFFFFFL) - offcurr;

#ifndef FIXIT_SCORE_CRASH
				if ( ((offset[subframe+2] & 0x00FFFFFFL) - offcurr) >= (0x00010000L - off16) ) {

					ptr = (char *)Add_Long_To_Pointer( ptr, offdiff );
					off16 = (unsigned long)lockptr & 0x00003FFFL;

					offcurr += offdiff;
					offdiff = 0;
				}
#endif

#ifdef NEVER
				// check for LCW'd rsd

				if ( ((offset[1] >> 24) & KF_LCW) ) {
					length = LCW_Uncompress( ptr, buffptr, buffsize );
				} else {
					length = buffsize;
					Apply_XOR_Delta( buffptr, Add_Long_To_Pointer( ptr, offdiff ) );
				}
#else
				length = buffsize;
				Apply_Delta(buffptr, Add_Long_To_Pointer(ptr, offdiff));
#endif

				currframe++;
				subframe += 2;

				if ( subframe >= (SUBFRAMEOFFS - 1) &&
					currframe <= framenumber ) {
					Mem_Copy( Add_Long_To_Pointer( dataptr,
									(((unsigned long)currframe << 3) +
									sizeof(KeyFrameHeaderType)) ),
						&offset[0], (long)(SUBFRAMEOFFS * sizeof(unsigned long)) );
					subframe = 0;
				}
			}
		}
	}
	return(length);
}


/***********************************************************************************************
 * Get_Build_Frame_Count -- Fetches the number of frames in data block.                        *
 *                                                                                             *
 *    Use this routine to determine the number of shapes within the data block.                *
 *                                                                                             *
 * INPUT:   dataptr  -- Pointer to the keyframe shape data block.                              *
 *                                                                                             *
 * OUTPUT:  Returns with the number of shapes in the data block.                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/25/1995 JLB : Commented.                                                               *
 *=============================================================================================*/
unsigned short Get_Build_Frame_Count(void const * dataptr)
{
	if (dataptr) {
		return(((KeyFrameHeaderType const *)dataptr)->frames);
	}
	return(0);
}


unsigned short Get_Build_Frame_X(void const * dataptr)
{
	if (dataptr) {
		return(((KeyFrameHeaderType const *)dataptr)->x);
	}
	return(0);
}


unsigned short Get_Build_Frame_Y(void const * dataptr)
{
	if (dataptr) {
		return(((KeyFrameHeaderType const *)dataptr)->y);
	}
	return(0);
}


/***********************************************************************************************
 * Get_Build_Frame_Width -- Fetches the width of the shape image.                              *
 *                                                                                             *
 *    Use this routine to fetch the width of the shapes within the keyframe shape data block.  *
 *    All shapes within the block have the same width.                                         *
 *                                                                                             *
 * INPUT:   dataptr  -- Pointer to the keyframe shape data block.                              *
 *                                                                                             *
 * OUTPUT:  Returns with the width of the shapes in the block -- expressed in pixels.          *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/25/1995 JLB : Commented                                                                *
 *=============================================================================================*/
unsigned short Get_Build_Frame_Width(void const * dataptr)
{
	if (dataptr) {
		return(((KeyFrameHeaderType const *)dataptr)->width);
	}
	return(0);
}


/***********************************************************************************************
 * Get_Build_Frame_Height -- Fetches the height of the shape image.                            *
 *                                                                                             *
 *    Use this routine to fetch the height of the shapes within the keyframe shape data block. *
 *    All shapes within the block have the same height.                                        *
 *                                                                                             *
 * INPUT:   dataptr  -- Pointer to the keyframe shape data block.                              *
 *                                                                                             *
 * OUTPUT:  Returns with the height of the shapes in the block -- expressed in pixels.         *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/25/1995 JLB : Commented                                                                *
 *=============================================================================================*/
unsigned short Get_Build_Frame_Height(void const * dataptr)
{
	if (dataptr) {
		return(((KeyFrameHeaderType const *)dataptr)->height);
	}
	return(0);
}


bool Get_Build_Frame_Palette(void const * dataptr, void * palette)
{
	if (dataptr && (((KeyFrameHeaderType const *)dataptr)->flags & 1)) {
		char const * ptr = (char const *)Add_Long_To_Pointer( dataptr,
							( (( (long)sizeof(unsigned long) << 1) *
								((KeyFrameHeaderType *) dataptr)->frames ) +
							16 + sizeof(KeyFrameHeaderType) ) );

		memcpy(palette, ptr, 768L);
		return(true);
	}
	return(false);
}
