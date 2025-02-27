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
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : WWLIB												*
 *                                                                         *
 *                    File Name : PALETTE.C											*
 *                                                                         *
 *                   Programmer : BILL STOKES										*
 *                                                                         *
 *                   Start Date : 6/20/91												*
 *                                                                         *
 *                  Last Update : August 2, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Note: This module contains dependencies upon the video system,				*
 * specifically Get_Video_Mode().														*
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Set_Palette -- sets the current palette											*
 *   Set_Palette_Color -- Set a color number in a palette to the data.     *
 *	  Fade_Palette_To -- Fades the current palette into another					*
 *   Determine_Bump_Rate -- determines desired bump rate for fading        *
 *   Bump_Palette -- increments the palette one step, for fading           *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/*
********************************* Includes **********************************
*/
#include <mem.h>
#include "wwstd.h"
#include "video.h"
#include "palette.h"
#include "timer.h"

/*
********************************* Constants *********************************
*/

/*
********************************** Globals **********************************
*/
extern "C" extern UBYTE  CurrentPalette[];		/* in pal.asm */

/*
******************************** Prototypes *********************************
*/

PRIVATE VOID cdecl Determine_Bump_Rate(VOID *palette, WORD delay, WORD *ticks, WORD *rate);
PRIVATE BOOL cdecl Bump_Palette(VOID *palette1, UWORD step);

/*
******************************** Code *********************************
*/

/***************************************************************************
 * Set_Palette -- sets the current palette											*
 *                                                                         *
 * INPUT:                                                                  *
 *		VOID *palette		- palette to set												*
 *                                                                         *
 * OUTPUT:                                                                 *
 *		none																						*
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/25/1994 SKB : Created.                                             *
 *   04/27/1994 BR : Converted to 32-bit                                   *
 *=========================================================================*/
VOID cdecl Set_Palette(VOID *palette)
{
	#if(IBM)
		Set_Palette_Range(palette);
	#else
		Copy_Palette(palette,CurrentPalette);
   	LoadRGB4(&Main_Screen->ViewPort,palette,32L);
	   LoadRGB4(AltVPort,palette,32L);
	#endif

}	/* end of Set_Palette */


/***************************************************************************
 * Set_Palette_Color -- Set a color number in a palette to the data.       *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *		VOID *palette	- palette to set color in										*
 *		WORD color		- which color index to set										*
 *		VOID *data		- RGB data for color												*
 *                                                                         *
 * OUTPUT:                                                                 *
 *		none																						*
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/25/1994 SKB : Created.                                             *
 *   04/27/1994 BR : Converted to 32-bit                                   *
 *=========================================================================*/
VOID cdecl Set_Palette_Color(VOID *palette, WORD color, VOID *data)
{
	/*
	---------------------- Return if 'palette' is NULL -----------------------
	*/
	if (!palette) return;

	/*
	------------------- Change the color & set the palette -------------------
	*/
	#if(IBM)
		memcpy(&((UBYTE *)palette)[color * RGB_BYTES], data, RGB_BYTES);
		Set_Palette_Range(palette);
	#else
		palette[color] = *(UWORD*)data;
		Set_Palette(palette);
	#endif

}	/* end of Set_Palette */


/***************************************************************************
 *	Fade_Palette_To -- Fades the current palette into another					*
 *                                                                         *
 * This will allow the palette to fade from current palette into the 		*
 * palette that was passed in.  This can be used to fade in and fade out.	*
 *                                                                         *
 * INPUT:      																				*
 *    BYTE  *palette1 - this is the palette to fade to.           			*
 *		UWORD delay		 -	fade with this timer count down							*
 *		VOID *callback  - user-defined callback function							*
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/20/1991  BS : Created.                                             *
 *=========================================================================*/
VOID Fade_Palette_To(VOID *palette1, UWORD delay, VOID (*callback)() )
{
	BOOL	changed;	// Flag that palette has changed this tick.
	WORD	jump;		// Gun values to jump per palette set.
	ULONG	timer;		// Tick count timer used for timing.
	WORD	ticksper;	// The ticks (fixed point) per bit jump.
	WORD	tickaccum;
	VOID (*cb_ptr)(VOID);	// callback function pointer

//	(VOID *)cb_ptr = callback;
	cb_ptr = callback;

	/*
	---------------------- Return if 'palette1' is NULL ----------------------
	*/
	if (!palette1) 
		return;

	/*
	--------------------- Fading only supported in MCGA ----------------------
	*/
	if (Get_Video_Mode() != MCGA_MODE) {	// was global GraphicMode
		Set_Palette(palette1);
		return;
	} 

	/*
	--------------------------- Get the bump rate ----------------------------
	*/
	Determine_Bump_Rate(palette1, delay, &ticksper, &jump);

	tickaccum = 0;							// init accumulated elapsed time
	timer = TickCount.Time(); 				// timer = current time
	do {
		changed = FALSE;

		tickaccum += ticksper;			// tickaccum = time of next change * 256
		timer += (tickaccum >> 8);		// timer = time of next change (rounded)
		tickaccum &= 0x0FF;				// shave off high byte, keep roundoff bits

		changed = Bump_Palette(palette1, jump);	// increment palette

		/*
		.................. Wait for time increment to elapse ..................
		*/
		if (changed) {
			while (TickCount.Time() < timer) {
				/*
				................. Update callback while waiting .................
				*/
				if (callback) {
#if LIB_EXTERNS_RESOLVED
					Sound_Callback();		// should be removed!
#endif
					(*cb_ptr)();
				}
			}
		}

#if LIB_EXTERNS_RESOLVED
		Sound_Callback();		// should be removed!
#endif
		if (callback) {
			(*cb_ptr)();
		}
	} while (changed);

}	/* end of Fade_Palette_To */


/***************************************************************************
 * Determine_Bump_Rate -- determines desired bump rate for fading          *
 *                                                                         *
 * INPUT:                                                                  *
 *		UBYTE *palette	- palette to fade to												*
 *		WORD delay		- desired time delay in 60ths of a second					*
 *		WORD *ticks		- output: loop ticks per color jump							*
 *		WORD *rate		- output: color gun increment rate							*
 *                                                                         *
 * OUTPUT:                                                                 *
 *		none																						*
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/27/1994 BR : Converted to 32-bit                                   *
 *   08/02/1994 SKB : Made private                                         *
 *=========================================================================*/
PRIVATE VOID cdecl Determine_Bump_Rate(VOID *palette, WORD delay, WORD *ticks, 
	WORD *rate)
{
	WORD gun1;		// Palette 1 gun value.
	WORD gun2;		// Palette 2 gun value.
	WORD diff;		// Maximum color gun difference.	
	WORD tp;			// Temporary tick accumulator.
	WORD index;		// Color gun working index.
	LONG t;			// Working tick intermediate value.
	WORD adiff;		// Absolute difference between guns.

	/*
	------------------------ Find max gun difference -------------------------
	*/
	diff = 0;
	for (index = 0; index < PALETTE_BYTES; index++) {
		gun1 = ((UBYTE *)palette)[index];
		gun2 = CurrentPalette[index];
		adiff = ABS(gun1-gun2);
		diff = MAX(diff, adiff);
	}

	/*------------------------------------------------------------------------
	ticks = (total time delay ) / (max gun diff)
	The value is computed based on (delay * 256), for fixed-point math;
	the lower bits represent the leftover from the division;  'ticks' is
	returned still shifted, so the low bits can be used to accumulate the
	time more accurately; the caller must shift the accumulated value down
	8 bits to determine the actual elapsed time!
	------------------------------------------------------------------------*/
	t = ((LONG)delay) << 8;
	if (diff) {
		t /= diff;
		t = MIN((long)t, (long)0x7FFF);
	}
	*ticks = (WORD)t;

	/*------------------------------------------------------------------------
	Adjust the color gun rate value if the time to fade is faster than can 
	reasonably be performed given the palette change, ie if (ticks>>8)==0,
	and thus less than 1/60 of a second
	------------------------------------------------------------------------*/
	tp = *ticks;
	*rate = 1;
	while (*rate <= diff && *ticks < 256) {
		*ticks += tp;
		*rate += 1;
	}

}	/* end of Determine_Bump_Rate */


/***************************************************************************
 * Bump_Palette -- increments the palette one step, for fading             *
 *                                                                         *
 * INPUT:                                                                  *
 *		palette1		- palette to fade towards											*
 *		step			- max step amount, determined by Determine_Bump_Rate		*
 *                                                                         *
 * OUTPUT:                                                                 *
 *		FALSE = no change, TRUE = changed												*
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/27/1994 BR : Created.                                              *
 *   08/02/1994 SKB : Made private                                         *
 *=========================================================================*/
#if(IBM)
PRIVATE BOOL cdecl Bump_Palette(VOID *palette1, UWORD step)
{
	BOOL	changed=FALSE;				// Flag that palette has changed this tick.
	WORD	index;						// Index to DAC register gun.
	WORD	gun1,gun2;					// Palette 1 gun value.
	UBYTE	palette[PALETTE_BYTES];	// copy of current palette

	/*
	---------------------- Return if 'palette1' is NULL ----------------------
	*/
	if (!palette1) 
		return (FALSE);

	/*
	--------------------- Fading only supported in MCGA ----------------------
	*/
	if (Get_Video_Mode() != MCGA_MODE) {	// was global GraphicMode
		Set_Palette(palette1);
		return (FALSE);
	} 

	/*
	------------------------ Copy the current palette ------------------------
	*/
	memcpy(palette, CurrentPalette, 768);

	/*
	----------------------- Loop through palette bytes -----------------------
	*/
	for (index = 0; index < PALETTE_BYTES; index++) {
		gun1 = ((UBYTE *)palette1)[index];
		gun2 = palette[index];

		/*
		............. If the colors match, go on to the next one ..............
		*/
		if (gun1 == gun2) continue;

		changed = TRUE;

		/*
		.................. Increment current palette's color ..................
		*/
		if (gun2 < gun1) {
			gun2 += step;
			gun2 = MIN(gun2, gun1);		// make sure we didn't overshoot it
		} 
		/*
		.................. Decrement current palette's color ..................
		*/
		else {
			gun2 -= step;
			gun2 = MAX(gun2, gun1);		// make sure we didn't overshoot it
		}

		palette[index] = gun2;
	}

	/*
	----------------- Set current palette to the new palette -----------------
	*/
	if (changed) {
		Set_Palette(&palette[0]);
	}

	return (changed);

}	/* end of Bump_Palette */

#else

	/* This is already implemented in asm on the Amiga */

#endif

/**************************** End of palette.cpp ***************************/


