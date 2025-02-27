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

/* $Header: /CounterStrike/STATBTN.H 1     3/03/97 10:25a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : STATBTN.H                                                    *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : 01/15/95                                                     *
 *                                                                                             *
 *                  Last Update : January 15, 1995 [JLB]                                       *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef STATBTN_H
#define STATBTN_H

#include	"gadget.h"
#include	"buff.h"

class StaticButtonClass : public GadgetClass
{
	public:
		StaticButtonClass(void);
		StaticButtonClass(unsigned id, char const * text, TextPrintType style, int x, int y, int w=-1, int h=-1);
		virtual int Draw_Me(int forced=false);
		virtual void Set_Text(char const * text, bool resize = false);

	protected:

		virtual void Draw_Background(void);
		virtual void Draw_Text(char const * text);

		/*
		**	If a background is to be preserved for this button, then this will point to
		**	a buffer that holds a pristine background image.
		*/
		Buffer Background;

		/*
		**	This points to a copy of the string that is used for the button's text.
		*/
		char * String;

		/*
		**	This is the print flags to use when rendering this button's text.
		*/
		TextPrintType PrintFlags;
};

#endif

