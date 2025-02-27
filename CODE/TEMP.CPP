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

THIS IS FROM SCORE.CPP

line 79
#ifdef FIXIT_SCORE_CRASH
void Disable_Uncompressed_Shapes (void);
void Enable_Uncompressed_Shapes (void);
#endif	//FIXIT


line 361
#ifdef FIXIT_SCORE_CRASH
	/*
	** Fix for the score screen crash due to uncompressed shape buffer overflow.
	*/
	Disable_Uncompressed_Shapes();
#endif	//FIXIT



LINE 844
#ifdef FIXIT_SCORE_CRASH
	/*
	** Fix for the score screen crash due to uncompressed shape buffer overflow.
	*/
	Enable_Uncompressed_Shapes();
#endif	//FIXIT


end of score

**********************


keyframe.cpp

line 116
#ifdef FIXIT_SCORE_CRASH
	char * ptr;
	unsigned long offcurr, offdiff;
#else
	char * ptr, * lockptr;
	unsigned long offcurr, off16, offdiff;
#endif


line 184
#ifndef FIXIT_SCORE_CRASH
		off16 = (unsigned long)lockptr & 0x00003FFFL;
#endif


line 194
#ifndef FIXIT_SCORE_CRASH
		if ( ((offset[2] & 0x00FFFFFFL) - offcurr) >= (0x00010000L - off16) ) {

			ptr = (char *)Add_Long_To_Pointer( ptr, offdiff );
			off16 = (unsigned long)ptr & 0x00003FFFL;

			offcurr += offdiff;
			offdiff = 0;
		}
#endif


line 228
#ifndef FIXIT_SCORE_CRASH
				if ( ((offset[subframe+2] & 0x00FFFFFFL) - offcurr) >= (0x00010000L - off16) ) {

					ptr = (char *)Add_Long_To_Pointer( ptr, offdiff );
					off16 = (unsigned long)lockptr & 0x00003FFFL;

					offcurr += offdiff;
					offdiff = 0;
				}
#endif


end keyframe
**********************


2keyframe.cpp

line 53
#ifdef FIXIT_SCORE_CRASH
/*
** Global required to fix the score screen crash bug by allowing disabling of uncompressed shapes.
*/
bool		OriginalUseBigShapeBuffer = false;
#endif	//FIXIT

end 2keyframe.cpp




