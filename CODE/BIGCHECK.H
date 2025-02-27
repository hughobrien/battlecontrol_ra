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

//	Bigcheck.h
//	ajw 9/14/98

#ifdef WOLAPI_INTEGRATION

#ifndef BIGCHECKBOX_H
#define BIGCHECKBOX_H

#include	"toggle.h"

#define BIGCHECK_OFFSETX	20
#define BIGCHECK_OFFSETY	0

//***********************************************************************************************
class BigCheckBoxClass : public ToggleClass
{
public:
	BigCheckBoxClass( unsigned id, int x, int y, int w, int h, const char* szCaptionIn, TextPrintType TextFlags, 
							bool bInitiallyChecked = false ) :
		ToggleClass( id, x, y, w, h ),
		TextFlags( TextFlags )
	{
		szCaption = new char[ strlen( szCaptionIn ) + 1 ];
		strcpy( szCaption, szCaptionIn );
		if( bInitiallyChecked )
			Turn_On();
		IsToggleType = 1;
	}
	virtual ~BigCheckBoxClass()
	{
		delete [] szCaption;
	}

	virtual int Draw_Me(int forced=false);
	virtual int Action(unsigned flags, KeyNumType & key);

	bool	Toggle()
	{
		if( IsOn )
		{
			Turn_Off();
			return false;
		}
		Turn_On();
		return true;
	}

protected:
	TextPrintType	TextFlags;
	char*			szCaption;

};

#endif

#endif
