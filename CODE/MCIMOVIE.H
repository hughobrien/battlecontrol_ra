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

#ifndef _MCIMOVIE_H_
#define _MCIMOVIE_H_

#include "function.h"

#ifdef MCIMPEG
#include <windows.h>
#include <windowsx.h>
#include <mmsystem.h>
#include <digitalv.h>
#include "watcom.h"

class MCIMovie
	{
	public:
		MCIMovie(HWND mainWindow);
		~MCIMovie();

		bool Open(const char* name, const char* device);
		bool Play(HWND window);
		bool Pause(void);
		bool Close(void);

		LONG GetWidth(void)
			{return ((mDeviceID) ? mWidth : 0);}

		LONG GetHeight(void)
			{return ((mDeviceID) ? mHeight : 0);}

	protected:
		HWND mMainWindow; // Application window
		HWND mMCIWindow; // Callback window
		char *mName;
		UINT mDeviceID;
		MCI_OPEN_PARMS mOpenParm;
		MCI_PLAY_PARMS mPlayParm;

		// Video stream dimension
		LONG mWidth, mHeight;

	private:
		bool SizeDestination(void);
		bool AttachWindow(HWND window);

		static int mRegistered;
		static WNDCLASS mWndClass;
		static HINSTANCE mInstance;
	};

#endif // MCIMPEG
#endif // _MCIMOVIE_H_
