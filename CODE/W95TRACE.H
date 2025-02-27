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

/*
    declarations for Win95 tracing facility
*/

#ifdef _DEBUG

#ifndef __TRACEW95__
#define __TRACEW95__

#include <windows.h>

// redefine all the MFC macros to point to us

#undef  TRACE
#define TRACE   OutputDebugStringW95

#undef  TRACE0
#define TRACE0   OutputDebugStringW95

#undef  TRACE1
#define TRACE1   OutputDebugStringW95

#undef  TRACE2
#define TRACE2   OutputDebugStringW95

#undef  TRACE3
#define TRACE3   OutputDebugStringW95

// redefine OutputDebugString so that it works with 
// API calls
#undef OutputDebugString
#define OutputDebugString   OutputDebugStringW95


// function declarations
void OutputDebugStringW95( LPCTSTR lpOutputString, ... );

#endif  //__TRACEW95__

#endif  // _DEBUG
