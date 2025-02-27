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

/* $Header: /CounterStrike/TXTLABEL.H 1     3/03/97 10:26a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : TXTLABEL.H                                                   *
 *                                                                                             *
 *                   Programmer : Bill Randolph																  *
 *                                                                                             *
 *                   Start Date : 02/06/95                                                     *
 *                                                                                             *
 *                  Last Update : February 6, 1995 [BR]													  *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef TXTLABEL_H
#define TXTLABEL_H

class TextLabelClass : public GadgetClass
{
	public:
		/*
		** Constructor/Destructor
		*/
		TextLabelClass(char *txt, int x, int y, RemapControlType * color,
			TextPrintType style);

		/*
		** Overloaded draw routine
		*/
		virtual int Draw_Me(int forced = false);

		/*
		** Sets the displayed text of the label
		*/
		virtual void Set_Text(char *txt) {Text = txt;};

		/*
		** General-purpose data fields
		*/
		unsigned long UserData1;
		unsigned long UserData2;
		TextPrintType Style;
		char *Text;
		RemapControlType * Color;
		int PixWidth;
};

#endif

