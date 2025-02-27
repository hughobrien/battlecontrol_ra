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

/* $Header: /CounterStrike/BLOWPIPE.H 1     3/03/97 10:24a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : BLOWPIPE.H                                                   *
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


#ifndef BLOWPIPE_H
#define BLOWPIPE_H

#include	"pipe.h"
#include	"blowfish.h"

/*
**	Performs Blowfish encryption/decryption on the data stream that is piped
**	through this class.
*/
class BlowPipe : public Pipe
{
	public:
		typedef enum CryptControl {
			ENCRYPT,
			DECRYPT
		} CryptControl;

		BlowPipe(CryptControl control) : BF(NULL), Counter(0), Control(control) {}
		virtual ~BlowPipe(void) {delete BF;BF = NULL;}
		virtual int Flush(void);

		virtual int Put(void const * source, int slen);

		// Submit key for blowfish engine.
		void Key(void const * key, int length);

	protected:
		/*
		**	The Blowfish engine used for encryption/decryption. If this pointer is
		**	NULL, then this indicates that the blowfish engine is not active and no
		**	key has been submitted. All data would pass through this pipe unchanged
		**	in that case.
		*/
		BlowfishEngine * BF;

	private:
		char Buffer[8];
		int Counter;
		CryptControl Control;

		BlowPipe(BlowPipe & rvalue);
		BlowPipe & operator = (BlowPipe const & pipe);
};


#endif
