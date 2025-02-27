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

/***************************************************************************
 **     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Font and text print 32 bit library       *
 *                                                                         *
 *                    File Name : FONT.H                                   *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : June 27, 1994                            *
 *                                                                         *
 *                  Last Update : June 29, 1994   [SKB]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   VVPC::Text_Print -- Text print into a virtual viewport.               *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef FONT_H
#define FONT_H

#ifndef GBUFFER_H
#include <gbuffer.h>
#endif

#ifndef VBUFFER_H
#include <vbuffer.h>
#endif

//////////////////////////////////////// Defines //////////////////////////////////////////

// defines for font header, offsets to block offsets

#define FONTINFOBLOCK			4
#define FONTOFFSETBLOCK			6
#define FONTWIDTHBLOCK			8
#define FONTDATABLOCK			10
#define FONTHEIGHTBLOCK			12

// defines for font info block

#define FONTINFOMAXHEIGHT		4
#define FONTINFOMAXWIDTH		5

//////////////////////////////////////// Prototypes //////////////////////////////////////////

/*=========================================================================*/
/* The following prototypes are for the file: SET_FONT.CPP						*/
/*=========================================================================*/

VOID *cdecl Set_Font(VOID const *fontptr);

/*=========================================================================*/
/* The following prototypes are for the file: FONT.CPP							*/
/*=========================================================================*/

WORD cdecl Char_Pixel_Width(BYTE chr);
UWORD cdecl String_Pixel_Width(BYTE const *string);
VOID cdecl Get_Next_Text_Print_XY(GraphicViewPortClass& vp, ULONG offset, INT *x, INT *y);
VOID cdecl Get_Next_Text_Print_XY(VideoViewPortClass& vp, ULONG offset, INT *x, INT *y);

/*=========================================================================*/
/* The following prototypes are for the file: LOADFONT.CPP	  					*/
/*=========================================================================*/

VOID *cdecl Load_Font(BYTE  const *name);

/*=========================================================================*/
/* The following prototypes are for the file: TEXTPRNT.ASM	  					*/
/*=========================================================================*/

#ifdef __cplusplus
extern "C" {
#endif


VOID Set_Font_Palette_Range(VOID *palette, INT start_idx, INT end_idx);


#ifdef __cplusplus
}
#endif

/*=========================================================================*/





//////////////////////////////////////// External varables ///////////////////////////////////////
extern "C" int FontXSpacing;
extern "C" int FontYSpacing;
extern BYTE FontWidth ;
extern BYTE FontHeight;
extern BYTE *FontWidthBlockPtr;


extern "C" VOID const *FontPtr;




#endif // FONT_H
