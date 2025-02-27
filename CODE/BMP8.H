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

#ifndef BMP8_H
#define BMP8_H

//#include<stdlib.h>
//#include<stdio.h>
//#include "wstypes.h"
//#include "winblows.h"

class BMP8
{
public:
	BMP8() : hBMP( NULL ), hPal( NULL ), hWnd( NULL )	{}
	~BMP8();

	bool	Init( const char* szFile, HWND hWnd );
	bool	Draw(void);  // call this from your WM_PAINT message

private:
	HBITMAP		hBMP;
	HPALETTE	hPal;
	HWND		hWnd;
};


#endif