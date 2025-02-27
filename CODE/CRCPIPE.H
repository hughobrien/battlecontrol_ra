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

/* $Header: /CounterStrike/CRCPIPE.H 1     3/03/97 10:24a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : CRCPIPE.H                                                    *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : 06/30/96                                                     *
 *                                                                                             *
 *                  Last Update : June 30, 1996 [JLB]                                          *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#ifndef CRCPIPE_H
#define CRCPIPE_H

#include	"pipe.h"
#include	"crc.h"

/*
**	This class doesn't modify the data being piped through, but it does examine it and build
**	a CRC value from the data.
*/
class CRCPipe : public Pipe
{
	public:
		CRCPipe(void) {}
		virtual int Put(void const * source, int slen);

		// Fetch the CRC value.
		long Result(void) const;

	protected:
		CRCEngine CRC;

	private:
		CRCPipe(CRCPipe & rvalue);
		CRCPipe & operator = (CRCPipe const & pipe);
};

#endif
