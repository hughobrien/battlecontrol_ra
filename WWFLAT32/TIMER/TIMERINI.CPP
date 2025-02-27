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
 *                 Project Name : Temp timer for 32bit lib                 *
 *                                                                         *
 *                    File Name : TIMERINI.CPP                             *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : July 6, 1994                             *
 *                                                                         *
 *                  Last Update : July 6, 1994   [SKB]                     *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Init_Timer_System -- Initialize the WW timer system.                  *
 *   Remove_Timer_System -- Removes the timer system.                      *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <wwstd.h>
#include <descmgmt.h>
#include "timer.H"

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Defines /////////////////////////////////////

#define COPY_FROM_MEM	TRUE

/////////////////////////////////////////////////////////////////////////////////
////////////////////////////// timera.asm functions//////////////////////////////

#ifdef __cplusplus
extern "C" {
#endif

extern VOID *Get_RM_Timer_Address(VOID);
extern ULONG Get_RM_Timer_Size(VOID);
extern BOOL Install_Timer_Interrupt(VOID *bin_ptr, UINT rm_size, UINT freq, BOOL partial);
extern BOOL Remove_Timer_Interrupt(VOID);

#ifdef __cplusplus
}
#endif

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Global Data /////////////////////////////////////

BOOL	TimerSystemOn	= FALSE;

// Global timers that the library or user can count on existing.
TimerClass					TickCount(BT_SYSTEM);
CountDownTimerClass		CountDown(BT_SYSTEM, 0);

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Code ////////////////////////////////////////

/***************************************************************************
 * INIT_TIMER_SYSTEM -- Initialize the WW timer system.                    *
 *                                                                         *
 *                                                                         *
 * INPUT: UINT : user timer frequency.													*
 *                                                                         *
 * OUTPUT:   BOOL success?                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/06/1994 SKB : Created.                                             *
 *=========================================================================*/
BOOL Init_Timer_System(UINT freq, BOOL partial)
{
	VOID		*binary;
	UINT		binsize;
	BOOL		success;

#if COPY_FROM_MEM

	// The binary is stuffed in an ASM module.
	// Get it's address and size.
	binary = Get_RM_Timer_Address();
	binsize = Get_RM_Timer_Size();
	
#else
	WORD fd;
	VOID *mem;

	// 
	// Open binary image of real mode timer code.
	// get its size and allocate a temp block for it.
	// Copy the file into the block and close the file
	//
	fd = Open("timer.ibn", READ);
	binsize = File_Size(fd);
	binary = Alloc(binsize, MEM_NORMAL);
	Read_File(fd, binary, binsize);
	Close_File(fd);

#endif // COPY_FROM_MEM

	// If no size, size too big or no address, then it's a bug.
	if (!binsize || (binsize > 0xFFFFL) || !binary) {
		return (FALSE);
	}

	TimerSystemOn = success = Install_Timer_Interrupt(binary, binsize, freq, partial);

#if !COPY_FROM_MEM
	// Free up the temp pointer.
	Free(mem);
#endif // !COPY_FROM_MEM

	if (success)  {
		if (!partial)
			TickCount.Start();
		return (TRUE);
	} else {
		Remove_Timer_Interrupt();
		return (FALSE);
	}
}



/***************************************************************************
 * REMOVE_TIMER_SYSTEM -- Removes the timer system.                        *
 *                                                                         *
 *                                                                         *
 * INPUT:   NONE.                                                          *
 *                                                                         *
 * OUTPUT:  BOOL was it removed successfuly                                *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/06/1994 SKB : Created.                                             *
 *=========================================================================*/
BOOL Remove_Timer_System(VOID)
{
	TimerSystemOn = FALSE;
	return(Remove_Timer_Interrupt());
}

