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

/* $Header: /CounterStrike/STRAW.H 1     3/03/97 10:25a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : STRAW.H                                                      *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : 07/02/96                                                     *
 *                                                                                             *
 *                  Last Update : July 2, 1996 [JLB]                                           *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef STRAW_H
#define STRAW_H

#include <stdlib.h>

/*
**	The "bool" integral type was defined by the C++ committee in
**	November of '94. Until the compiler supports this, use the following
**	definition.
*/
#ifndef __BORLANDC__
#ifndef TRUE_FALSE_DEFINED
#define TRUE_FALSE_DEFINED
enum {false=0,true=1};
typedef int bool;
#endif
#endif


/*
**	This is a demand driven data carrier. It will retrieve the byte request by passing
**	the request down the chain (possibly processing on the way) in order to fulfill the
**	data request. Without being derived, this class merely passes the data through. Derived
**	versions are presumed to modify the data in some useful way or monitor the data
**	flow.
*/
class Straw
{
	public:
		Straw(void) : ChainTo(0), ChainFrom(0) {}
		virtual ~Straw(void);

		virtual void Get_From(Straw * pipe);
		void Get_From(Straw & pipe) {Get_From(&pipe);}
		virtual int Get(void * buffer, int slen);

		/*
		**	Pointer to the next pipe segment in the chain.
		*/
		Straw * ChainTo;
		Straw * ChainFrom;

	private:

		/*
		**	Disable the copy constructor and assignment operator.
		*/
		Straw(Straw & rvalue);
		Straw & operator = (Straw const & pipe);
};


#endif
