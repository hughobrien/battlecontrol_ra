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

/* $Header: /CounterStrike/MPU.CPP 1     3/03/97 10:25a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : MPU.CPP                                                      *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : 07/17/96                                                     *
 *                                                                                             *
 *                  Last Update : July 17, 1996 [JLB]                                          *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"MPU.H"


#ifdef __BORLANDC__
uint32_t __cdecl Get_CPU_Clock(uint32_t & high)
{
	__asm db 0fh,031h
	__asm mov [high],edx
	return(_EAX);
}
#elif !defined(__WATCOMC__)
uint32_t Get_CPU_Clock(uint32_t & high)
{
#if defined(__i386__) || defined(__x86_64__)
	uint32_t low;
	__asm__ __volatile__("rdtsc" : "=a"(low), "=d"(high));
	return low;
#else
#error Get_CPU_Clock needs an implementation for this CPU architecture.
#endif
}
#endif
