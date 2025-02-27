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

/* $Header: /CounterStrike/CRATE.H 1     3/03/97 10:24a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : CRATE.H                                                      *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : 08/26/96                                                     *
 *                                                                                             *
 *                  Last Update : August 26, 1996 [JLB]                                        *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef CRATE_H
#define CRATE_H

#include	"ftimer.h"
#include	"jshell.h"


/*
**	The "bool" integral type was defined by the C++ comittee in
**	November of '94. Until the compiler supports this, use the following
**	definition.
*/
#ifndef __BORLANDC__
#ifndef TRUE_FALSE_DEFINED
#define TRUE_FALSE_DEFINED
enum {false=0,true=1};
typedef int bool;
#endif
#endif

class CrateClass {
	public:
		CrateClass(void) : Timer(NoInitClass()), Cell(-1) {}
		void Init(void) {Make_Invalid();}
		bool Create_Crate(CELL cell);
		bool Is_Here(CELL cell) const {return(Is_Valid() && cell == Cell);}
		bool Remove_It(void);
		bool Is_Expired(void) const {return(Is_Valid() && Timer == 0);}
		bool Is_Valid(void) const {return(Cell != -1);}

	private:
		static bool Put_Crate(CELL & cell);
		static bool Get_Crate(CELL cell);

		void Make_Invalid(void) {Cell = -1;Timer.Stop();}

		CDTimerClass<FrameTimerClass> Timer;
		CELL Cell;
};


#endif
