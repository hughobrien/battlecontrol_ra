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
 **   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : wwlib32                                  *
 *                                                                         *
 *                    File Name : PALTOPAL.CPP                             *
 *                                                                         *
 *                   Programmer : Bill Randolph                            *
 *                                                                         *
 *                   Start Date : May 2, 1994                              *
 *                                                                         *
 *                  Last Update : May 2, 1994   [BR]                       *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Morph_Palette -- morphs a palette from source to destination          *
 *   Palette_To_Palette -- morph src palette to a dst palette              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/*
********************************* Includes **********************************
*/
#include "wwstd.h"
#include "video.h"
#include "palette.h"
#include "timer.h"

/*
********************************* Constants *********************************
*/
#define SCALE(a,b,c) (((((LONG)(a)<<8) / (LONG)(b) ) * (ULONG)(c)) >>8)


/*
********************************** Globals **********************************
*/

/*
******************************** Prototypes *********************************
*/

PRIVATE WORD cdecl Palette_To_Palette(VOID *src_palette, VOID *dst_palette, ULONG current_time, ULONG delay);


/***************************************************************************
 * Morph_Palette -- morphs a palette from source to destination            *
 *                                                                         *
 * INPUT:                                                                  *
 *		VOID *src_pal	- starting palette												*
 *		VOID *dst_pal	- ending palette													*
 *		UWORD delay	- time delay in 60ths of a second							*
 *		VOID *callback	- user-defined callback, NULL if none						*
 *                                                                         *
 * OUTPUT:                                                                 *
 *		none.																						*
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/02/1994 BR : Created.                                              *
 *=========================================================================*/
VOID cdecl Morph_Palette (VOID *src_pal, VOID *dst_pal, UWORD delay,
	VOID (*callback) (VOID) )
{
	WORD	result;
	ULONG	pal_start = TickCount.Time();
	VOID   (*cb_ptr) ( VOID ) ;	// callback function pointer

//	(VOID *)cb_ptr = callback;
	cb_ptr = callback ;

	/*===================================================================*/
	/* Make sure that we don't go too fast but also make sure we keep		*/
	/*		processing the morph palette if we have one.							*/
	/*===================================================================*/
	while (1) {
		if (src_pal && dst_pal) {
			result = Palette_To_Palette (src_pal, dst_pal, 
				(TickCount.Time() - pal_start), (ULONG)delay);
			if (!result)
				break;

			if (callback) {
				(*cb_ptr)();
			}
		}
	}

	return;

}	/* end of Morph_Palette */


/***************************************************************************
 * Palette_To_Palette -- morph src palette to a dst palette                *
 *                                                                         *
 * Creates & sets a palette that's in-between 'src_palette' & 					*
 * 'dst_palette'; how close it is to dst_palette is based on how close 		*
 * 'current_time' is to 'delay'.  'current_time' & 'delay' are based on		*
 * 0 being the start time.																	*
 *                                                                         *
 * INPUT:               VOID *src_palette =  palette we want to morph from *
 *                      VOID *dst_palette =  palette we want to morph to   *
 *                      LONG current_time =  time we started morph pal		*
 *                      LONG delay         = time we want the morph to take*
 *                                                                         *
 * OUTPUT:					WORD if the time had elapsed and no chages were		*
 *									  necessary this routine returns FALSE				*
 *									  otherwise it will always return TRUE (this		*
 *									  was necessary to detect the end of the ice		*
 *									  effect.													*
 *                                                                         *
 * HISTORY:                                                                *
 *   05/24/1993  MC : Created.                                             *
 *=========================================================================*/
PRIVATE WORD cdecl Palette_To_Palette(VOID *src_palette, VOID *dst_palette, 
	ULONG current_time, ULONG delay)
{
	BYTE	colour;
	BYTE	diff;
	WORD	chgval;
	WORD	lp;
	WORD	change;
	static BYTE  palette[768];

	/*======================================================================*/
	/* Loop through each RGB value attempting to change it to the correct	*/
	/*		color.																				*/
	/*======================================================================*/
	for (change = lp = 0; lp < 768; lp++) {
		if (current_time < delay ) {
			diff		= ( ( ((BYTE *)dst_palette)[lp] & 63) - 
				( ((BYTE *)src_palette)[lp] & 63) );
			if (diff) 
				change = TRUE;
			chgval	= SCALE(diff, delay, current_time);
			colour 	= ( ((BYTE *)src_palette)[lp] & 63) + chgval;
		} 
		else {
			colour = ((BYTE *)dst_palette)[lp] & 63;
			change = FALSE;
		}
		palette[lp] = colour;
	}
	/*======================================================================*/
	/* Set the palette to the color that we created.								*/
	/*======================================================================*/
	Set_Palette(palette);
	return(change);

}	/* end of Palette_To_Palette */


/*************************** End of morphpal.cpp ***************************/

