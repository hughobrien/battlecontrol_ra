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

/* $Header:   F:\projects\c&c0\vcs\code\dpmi.h_v   4.43   05 Jul 1996 17:58:40   JOE_BOSTIC  $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : DPMI.H                                                       *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : July 2, 1994                                                 *
 *                                                                                             *
 *                  Last Update : July 2, 1994   [JLB]                                         *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef DPMI_Hx
#define DPMI_Hx
#include	<dos.h>
#include	<stdlib.h>
#include	<stdio.h>
#include	<mem.h>
#include	<stdint.h>


extern void output(short port, short data);


class DOSSegmentClass {
		/*
		**	This is the selector/segment value. In real mode it is the segment, in protected
		**	mode it is the selector (also 16 bits). This value is moved into DS or ES when
		**	accessing memory.
		** Note: in Watcom flat addressing, Selector == Segment<<4 (ex: 0A0000h)
		*/
		uintptr_t Selector;

		/*
		**	These are C equivalents for pushing and popping the DS segment register. By using
		**	these, it is possible to create very small code that uses a segment and
		**	offset without damaging the DS register. These are especially useful in protected
		**	mode, but they are legal in real mode as well.
		*/
		void Push_DS(void) {/*__emit__(0x1E);*/};
		void Pop_DS(void) {/*__emit__(0x1F);*/};

	public:
		DOSSegmentClass(void);
		~DOSSegmentClass(void);
		DOSSegmentClass(uint16_t segment, int32_t size=(1024L*64L));

		uintptr_t Get_Selector(void);

		/*
		**	This routine is used to assign where the descriptor actually points to in
		**	low DOS memory. In real mode, this is a simple segment assignment and the size
		**	is always 64K regardless of what is specified. In protected mode, the segment
		**	is used to update the selector and the size can be any length.
		** In Watcom flat mode, it sets Selector == segment<<4
		*/
		void Assign(uint16_t segment, int32_t size=(1024L*64L));

		/*
		**	These routines will move the data to/from regular memory and the segment/descriptor
		**	memory.
		*/
		void Copy_To(void *source, int dest, int size);
		void Copy_From(void *dest, int source, int size);
		void Copy_Word_To(int16_t data, int dest);
		void Copy_Byte_To(uint8_t data, int dest);
		void Copy_DWord_To(int32_t data, int dest);
		int16_t Copy_Word_From(int source);
		uint8_t Copy_Byte_From(int source);
		int32_t Copy_DWord_From(int source);

		/*
		**	These routines move data around between sections of segmented (descriptor) memory.
		**	Typically, this is used when accessing DOS memory in protected mode or when dealing
		**	with hard memory areas such as the screen.
		*/
		static void Copy(DOSSegmentClass &src, int soffset, DOSSegmentClass &dest, int doffset, int size);
		static void Swap(DOSSegmentClass &src, int soffset, DOSSegmentClass &dest, int doffset, int size);
};


inline DOSSegmentClass::DOSSegmentClass(void)
{
	Selector = 0xB0000;
}

inline DOSSegmentClass::~DOSSegmentClass(void)
{
}

inline void DOSSegmentClass::Copy_Word_To(int16_t data, int dest)
{
	*(int16_t *)(Selector+dest) = data;
}

inline void DOSSegmentClass::Copy_Byte_To(uint8_t data, int dest)
{
	*(uint8_t *)(Selector+dest) = data;
}

inline void DOSSegmentClass::Copy_DWord_To(int32_t data, int dest)
{
	*(int32_t *)(Selector+dest) = data;
}

inline void DOSSegmentClass::Assign(uint16_t segment, int32_t)
{
	Selector = (uintptr_t)segment << 4;
}

inline DOSSegmentClass::DOSSegmentClass(uint16_t segment, int32_t)
{
	Assign(segment);
}

inline void DOSSegmentClass::Copy_To(void *source, int dest, int size)
{
	memmove((void*)(Selector+dest), source, (unsigned)size);
}

inline void DOSSegmentClass::Copy_From(void *dest, int source, int size)
{
	memmove(dest, (void*)(Selector+source), (unsigned)size);
}

inline void DOSSegmentClass::Copy(DOSSegmentClass &src, int soffset, DOSSegmentClass &dest, int doffset, int size) {
	memmove((void*)(dest.Selector+doffset), (void*)(src.Selector+soffset), (unsigned)size);
}

inline int16_t DOSSegmentClass::Copy_Word_From(int source)
{
	return *(int16_t *)(Selector+source);
}

inline uint8_t DOSSegmentClass::Copy_Byte_From(int source)
{
	return *(uint8_t *)(Selector+source);
}

inline int32_t DOSSegmentClass::Copy_DWord_From(int source)
{
	return *(int32_t *)(Selector+source);
}

inline uintptr_t DOSSegmentClass::Get_Selector(void)
{
	return Selector;
}
#endif
