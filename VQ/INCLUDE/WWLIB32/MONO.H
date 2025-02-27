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
 *                 Project Name : Mono Sub-system                          *
 *                                                                         *
 *                    File Name : MONO.H                                   *
 *                                                                         *
 *                   Programmer : Joe Bostic                               *
 *             32Bit Programmer : Jeff Wilson                              *
 *                                                                         *
 *                   Start Date : March 28, 1994                           *
 *                                                                         *
 *                  Last Update : March 28, 1994   []                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#ifndef MONO_H
#define MONO_H

// C++ Routines
//==================================================================

// Mono Screen routines
//==================================================================
int	Initialize_Mono_Screen ( void );
							   

// C Routines
//==================================================================
#ifdef __cplusplus
extern "C" {
#endif

// Mono Screen routines
//===================================================================
	extern	unsigned	MonoScreen;
	extern	unsigned	MonoEnabled;
			
	extern	void Mono_Set_Cursor(int x, int y);
	extern 	void Mono_Clear_Screen(void); 
	extern 	void Mono_Scroll(int lines);
	extern 	void Mono_Put_Char(char character, int attrib=2);
	extern 	void Mono_Draw_Rect(int x, int y, int w, int h, int attrib=2, int thick=0);
	extern	void Mono_Text_Print(void const *text, int x, int y, int attrib=2);
	extern	void Mono_Print(void const *text);
	extern 	void Mono_View_Page(int page);
	extern	int Mono_Printf(char const *string, ...);
								
#ifdef __cplusplus
}
#endif


#endif

