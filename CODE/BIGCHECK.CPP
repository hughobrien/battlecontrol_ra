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

//	BigCheck.cpp
//	ajw 9/14/98

#ifdef WOLAPI_INTEGRATION

#include	"function.h"
#include	"bigcheck.h"

//***********************************************************************************************
int BigCheckBoxClass::Draw_Me( int forced )
{
	if (ToggleClass::Draw_Me(forced))
	{
		Hide_Mouse();

		if( !IsOn )
		{
			if( !IsDisabled )
				CC_Draw_Shape( MFCD::Retrieve( "bigcheck.shp" ), 0, X, Y, WINDOW_MAIN, SHAPE_NORMAL );
			else
				CC_Draw_Shape( MFCD::Retrieve( "bigcheck.shp" ), 2, X, Y, WINDOW_MAIN, SHAPE_NORMAL );
		}
		else
		{
			if( !IsDisabled )
				CC_Draw_Shape( MFCD::Retrieve( "bigcheck.shp" ), 1, X, Y, WINDOW_MAIN, SHAPE_NORMAL );
			else
				CC_Draw_Shape( MFCD::Retrieve( "bigcheck.shp" ), 3, X, Y, WINDOW_MAIN, SHAPE_NORMAL );
		}

		TextPrintType flags = TextFlags;
		
		RemapControlType* pScheme;
		
//		if( !IsDisabled )
			pScheme = GadgetClass::Get_Color_Scheme();
//		else
//		{
//			pScheme = &GreyScheme;
//			flags = flags | TPF_MEDIUM_COLOR;
//		}

		Conquer_Clip_Text_Print( szCaption, X + BIGCHECK_OFFSETX, Y + BIGCHECK_OFFSETY, pScheme, TBLACK, flags, Width, 0 );

		Show_Mouse();
		return true;
	}
	return false;
}

//***********************************************************************************************
int BigCheckBoxClass::Action(unsigned flags, KeyNumType & key)
{
/*	if( flags & LEFTPRESS )
	{
		if (IsOn) {
			Turn_Off();
		} else {
			Turn_On();
		}
	}
*/
	return(ToggleClass::Action(flags, key));
}

#endif
