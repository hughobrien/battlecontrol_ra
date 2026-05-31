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

/* $Header: /CounterStrike/WATCOM.H 1     3/03/97 10:26a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : WATCOM.H                                                     *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : 03/12/95                                                     *
 *                                                                                             *
 *                  Last Update : March 12, 1995 [JLB]                                         *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef WATCOM_H
#define WATCOM_H

/*
**	Zig builds this code through Clang, whose libc surface does not provide the
**	legacy MS/Watcom string helpers used throughout the original source.
*/
#if defined(__clang__)
#include <ctype.h>
#include <stdint.h>
#include <string.h>

static inline int WW_Stricmp(char const * left, char const * right)
{
	while (*left && *right) {
		int l = tolower((uint8_t)*left);
		int r = tolower((uint8_t)*right);
		if (l != r) {
			return l - r;
		}
		left++;
		right++;
	}
	return tolower((uint8_t)*left) - tolower((uint8_t)*right);
}

static inline int WW_Memicmp(void const * left, void const * right, size_t length)
{
	uint8_t const * lptr = (uint8_t const *)left;
	uint8_t const * rptr = (uint8_t const *)right;
	for (size_t index = 0; index < length; index++) {
		int l = tolower(lptr[index]);
		int r = tolower(rptr[index]);
		if (l != r) {
			return l - r;
		}
	}
	return 0;
}

static inline char *WW_Strupr(char * text)
{
	for (char * ptr = text; *ptr; ptr++) {
		*ptr = (char)toupper((uint8_t)*ptr);
	}
	return text;
}

static inline char *WW_Strlwr(char * text)
{
	for (char * ptr = text; *ptr; ptr++) {
		*ptr = (char)tolower((uint8_t)*ptr);
	}
	return text;
}

static inline char *WW_Strrev(char * text)
{
	if (text && *text) {
		char * left = text;
		char * right = text + strlen(text) - 1;
		while (left < right) {
			char temp = *left;
			*left++ = *right;
			*right-- = temp;
		}
	}
	return text;
}

#define stricmp WW_Stricmp
#define strcmpi WW_Stricmp
#define _stricmp WW_Stricmp
#define memicmp WW_Memicmp
#define strupr WW_Strupr
#define _strlwr WW_Strlwr
#define strrev WW_Strrev
#endif

// Turn all warnings into errors.
#pragma warning * 0

// Disables warning when "sizeof" is used on an object with virtual functions.
#pragma warning 549 9

// Disable the "Integral value may be truncated during assignment or initialization".
#pragma warning 389 9

// Allow constructing a temporary to be used as a parameter.
#pragma warning 604 9

// Disable the construct resolved as an expression warning.
#pragma warning 595 9

// Disable the strange "construct resolved as a declaration/type" warning.
#pragma warning 594 9

// Disable the "pre-compiled header file cannot be used" warning.
#pragma warning 698 9

// Disable the "temporary object used to initialize a non-constant reference" warning.
#pragma warning 665 9

// Disable the "pointer or reference truncated by cast. Cast is supposed to REMOVE warnings, not create them.
#pragma warning 579 9

// Disable the warning that suggests a null destructor be placed in class definition.
#pragma warning 656 9

// Disable the warning about moving empty constructors/destructors to the class declaration.
#pragma warning 657 9

// No virtual destructor is not an error in C&C.
#pragma warning 004 9

// Turns off unreferenced function parameter warning.
//#pragma off(unreferenced)


// Fix deficiency in Watcom so that true/false will be defined.
#if !defined(__cplusplus) && !defined(__BORLANDC__)
#ifndef TRUE_FALSE_DEFINED
#define TRUE_FALSE_DEFINED
enum {false=0,true=1};
typedef int bool;
#endif
#endif

#endif
