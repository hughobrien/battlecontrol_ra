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

/***************************************************************************
 **      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood 32 bit Library                  *
 *                                                                         *
 *                    File Name : SOUNDINT.CPP                             *
 *                                                                         *
 *                   Programmer : Phil W. Gorrow                           *
 *                                                                         *
 *                   Start Date : June 23, 1995                            *
 *                                                                         *
 *                  Last Update : June 28, 1995   [PWG]                    *
 *                                                                         *
 * This module contains all of the functions that are used within our      *
 * sound interrupt.  They are stored in a seperate module because memory	*
 * around these functions must be locked or they will cause a read to		*
 * be generated while in an interrupt.													*
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Simple_Copy -- Copyies 1 or 2 source chuncks to a dest                *
 *   Sample_Copy -- Copies sound data from source format to raw format.    *
 *   DigiCallback -- Low level double buffering handler.                   *
 *   save_my_regs -- Inline function which will save assembly regs         *
 *   restore_my_regs -- Inline function which will restore saved registes  *
 *   Audio_Add_Long_To_Pointer -- Adds an offset to a ptr casted void      *
 *   Init_Locked_Data -- Initializes sound driver locked data              *
 *   Audio_Mem_Set -- Quick see routine to set memory to a value           *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

#pragma pack(4)
#include "soundint.h"
//#include "mem.h"

/***************************************************************************
** All routines past this point must be locked for the sound driver to	  **
** function under a VCPI memory manager.  These locks are unnecessary if  **
** the driver does not have to run under windows or does not use virtual  **
** memory.                                                                **
***************************************************************************/
	
/***************************************************************************
 * SAVE_MY_REGS -- Inline function which will save assembly regs           *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/23/1995 PWG : Created.                                             *
 *=========================================================================*/

#pragma aux save_my_regs =		\
		"pushfd"			\
		"pushad"			\
		"push ds"		\
		"push es"		\
		"push fs"		\
		"push gs"		\
		"push ds"		\
		"pop  es";

#pragma aux enable = \
		"sti";

#pragma aux disable = \
		"cli";

/***************************************************************************
 * RESTORE_MY_REGS -- Inline function which will restore saved registers   *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/23/1995 PWG : Created.                                             *
 *=========================================================================*/

#pragma aux restore_my_regs =	\
		"pop	gs"		\
		"pop	fs"		\
		"pop	es"		\
		"pop	ds"		\
		"popad"			\
		"popfd";

/***************************************************************************
 * SIMPLE_COPY -- Copyies 1 or 2 source chuncks to a dest                  *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/23/1995 PWG : Created.                                             *
 *=========================================================================*/
long Simple_Copy(void ** source, long * ssize, void ** alternate, long * altsize, void **dest, long size)
{


	long	out = 0;		// Number of bytes copied to the destination.

	/*
	**	It could happen that entering this routine, the source buffer
	**	has been exhausted, but the alternate buffer is still valid.
	**	Move the alternate into the primary position before proceeding.
	*/
	if (!(*ssize)) {
		*source = *alternate;
		*ssize = *altsize;
		*alternate = NULL;
		*altsize = 0;
	}

	if (*source && *ssize) {
		long	s;				// Scratch length var.

		/*
		**	Copy as much as possible from the primary source, but no
		**	more than the primary source has to offer.
		*/
		s = size;
		if (*ssize < s) s = *ssize;
		Mem_Copy(*source, *dest, s);
		*source = Audio_Add_Long_To_Pointer(*source, s);
		*ssize -= s;
		*dest = Audio_Add_Long_To_Pointer(*dest, s);
		size -= s;
		out += s;

		/*
		**	If the primary source was insufficient to fill the request, then
		**	move the alternate into the primary position and try again.
		*/
		if (size) {
			*source = *alternate;
			*ssize = *altsize;
			*alternate = 0;
			*altsize = 0;
			out += Simple_Copy(source, ssize, alternate, altsize, dest, size);
		}
	}

	return(out);
}

/***********************************************************************************************
 * Sample_Copy -- Copies sound data from source format to raw format.                          *
 *                                                                                             *
 *    This routine is used to copy the sound data (possibly compressed) to the destination     *
 *    buffer in raw format.                                                                    *
 *                                                                                             *
 * INPUT:   source   -- Pointer to the source data (possibly compressed).                      *
 *                                                                                             *
 *          dest     -- Pointer to the destination buffer.                                     *
 *                                                                                             *
 *          size     -- The size of the destination buffer.                                    *
 *                                                                                             *
 * OUTPUT:  Returns with the number of bytes placed into the output buffer.  This is usually   *
 *          the number of bytes requested except in the case when the source is exhausted.     *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/03/1994 JLB : Created.                                                                 *
 *   09/04/1994 JLB : Revamped entirely.                                                       *
 *=============================================================================================*/
#pragma argsused
long Sample_Copy(SampleTrackerType *st, void ** source, long * ssize, void ** alternate, long * altsize, void * dest, long size, SCompressType scomp, void * trailer, WORD *trailersize)
{

	long	s;
	long	datasize = 0;		// Output bytes.

	switch (scomp) {
		default:

		case SCOMP_NONE:
			datasize = Simple_Copy(source, ssize, alternate, altsize, &dest, size);
			break;

		case SCOMP_WESTWOOD:
		case SCOMP_SOS:
			while (size > 0) {

				/*
				**	The block spans two buffers.  It must be copied down to 
				**	a staging area before it can be decompressed.
				*/
				{
					long magic;
					unsigned short fsize;
					unsigned short dsize;
					void *fptr;
					void *dptr;
					void *mptr;

					fptr = &fsize;
					dptr = &dsize;
					mptr = &magic;

					s = Simple_Copy(source, ssize, alternate, altsize, &fptr, sizeof(fsize));
					if (s < sizeof(fsize)) {
						return datasize;
					}
					s = Simple_Copy(source, ssize, alternate, altsize, &dptr, sizeof(dsize));
					if (s < sizeof(dsize) || size < dsize) {
						return datasize;
					}

					s = Simple_Copy(source, ssize, alternate, altsize, &mptr, sizeof(magic));
					if (s < sizeof(magic) || magic != LockedData.MagicNumber) {
						return datasize;
					}

					/*
					**	If the frame and uncompressed data size are identical, then this
					**	indicates that the frame is not compressed.  Just copy it directly
					**	to the destination buffer in this case.
					*/
					if (fsize == dsize) {
						s = Simple_Copy(source, ssize, alternate, altsize, &dest, fsize);
						if (s < dsize) {
							return (datasize);
						}
					} else {

						/*
						**	The frame was compressed, so copy it to the staging buffer, and then
						**	uncompress it into the final destination buffer.
						*/
						fptr = LockedData.UncompBuffer;
						s = Simple_Copy(source, ssize, alternate, altsize, &fptr, fsize);
						if (s < fsize) {
							return (datasize);
						}
						if (scomp == SCOMP_WESTWOOD) {
							Decompress_Frame(LockedData.UncompBuffer, dest, dsize);
						} else {
							st->sosinfo.lpSource = (char *)LockedData.UncompBuffer;
							st->sosinfo.lpDest	 = (char *)dest;
							sosCODECDecompressData(&st->sosinfo, dsize);
						}
						dest = Audio_Add_Long_To_Pointer(dest, dsize);
					}
					datasize += dsize;
					size -= dsize;
				}
			}

			break;
	}
	return(datasize);
}

VOID far cdecl maintenance_callback(VOID)
{
	save_my_regs();
	int					index;
	SampleTrackerType	*st;

	if (!LockedData._int && LockedData.DigiHandle != -1 && LockedData.ServiceSomething) {

		LockedData._int++;
		enable();
		LockedData.ServiceSomething = FALSE;
		st = &LockedData.SampleTracker[0];
		for (index = 0; index < LockedData.MaxSamples; index++) {

			if (st->Active) {

				/*
				**	General service routine to handle moving small blocks from the
				**	source into the low RAM staging buffers.  If the source is
				**	compressed, then this will also uncompress it as the copy
				**	is performed.
				*/
				if (st->Service) {
					if (st->DontTouch) {
						LockedData.ServiceSomething = TRUE;
					} else {
						st->Service = FALSE;

#if(FALSE)
						st->DataLength = SFX_MINI_STAGE_BUFFER_SIZE;
#else
						st->DataLength = Sample_Copy(	st,
																&st->Source, 
																&st->Remainder, 
																&st->QueueBuffer, 
																&st->QueueSize, 
																st->Buffer[st->Index], 
																SFX_MINI_STAGE_BUFFER_SIZE, 
																st->Compression, 
																&st->Trailer[0], 
																&st->TrailerLen);

#endif
					}
				}

				/*
				**	For file streamed samples, fill the queue pointer if needed.
				**	This allows for delays in calling the Sound_Callback function.
				*/
				if (!st->DontTouch && !st->QueueBuffer && st->FilePending) {
					st->QueueBuffer = Audio_Add_Long_To_Pointer(st->FileBuffer, (long)(st->Odd%LockedData.StreamBufferCount)*(long)LockedData.StreamBufferSize);
					st->FilePending--;
					st->Odd++;
					if (!st->FilePending) {
						st->QueueSize = st->FilePendingSize;
					} else {
						st->QueueSize = LockedData.StreamBufferSize;
					}
				}

			}

			/*
			**	Advance to the next sample control structure.
			*/
			st++;
		}
		LockedData._int--;
	}

	
	if (!LockedData._int) {

		LockedData._int++;
		st = &LockedData.SampleTracker[0];
		for (index = 0; index < LockedData.MaxSamples; index++) {

			/*
			**	If there are any samples that require fading, then do so at this
			**	time.
			*/
			if (st->Active && st->Reducer && st->Volume) {
				if (st->Reducer >= st->Volume) {
					st->Volume = 0;
				} else {
					st->Volume -= st->Reducer;
				}
				
				if (st->IsScore) {
					sosDIGISetSampleVolume(LockedData.DigiHandle, st->Handle, (st->Volume>>8) * LockedData.ScoreVolume);
				} else {
					sosDIGISetSampleVolume(LockedData.DigiHandle, st->Handle, (st->Volume>>8) * LockedData.SoundVolume);
				}
			}
			st++;
		}
		LockedData._int--;
	}
	restore_my_regs();
}
/***********************************************************************************************
 * DigiCallback -- Low level double buffering handler.                                         *
 *                                                                                             *
 *    This routine is called in an interrupt to handle the double                              *
 *    buffering of digital audio.  This routine is the interface between                       *
 *    the buffers maintained by Sound_Callback() and the HMI driver                            *
 *    itself.                                                                                  *
 *                                                                                             *
 * INPUT:   driverhandle   -- The handle to the HMI driver.                                    *
 *                                                                                             *
 *          callsource     -- Code indicating the reason for the callback.                     *
 *                                                                                             *
 *          sampleid       -- The ID number of the sample itself.                              *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   This is called in an interrupt so it return as quickly as                       *
 *             possible.                                                                       *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
VOID cdecl far DigiCallback(unsigned int driverhandle, unsigned int callsource, unsigned int sampleid)
{
	SampleTrackerType	*st;
	int	index;


	/*
	**	Find the correct control structure for the handle specified.
	*/
	for (index = 0; index < LockedData.MaxSamples; index++) {
		st = &LockedData.SampleTracker[index];
		if (st->Active && st->Handle == sampleid) {
			break;
		}
	}
	if (index == LockedData.MaxSamples) {
		return;
	}

	if (driverhandle == LockedData.DigiHandle) {

		switch (callsource) {

			/*
			**	The sample is now no longer audible.  Don't stop the sample
			**	tracking if a servicing is needed.  If it is needed then
			**	obviously the sample isn't quite done.
			*/
			case _SAMPLE_DONE:
				st->Active = FALSE;
				if (!st->IsScore) {
//					DPMI_Unlock(st->Original, st->OriginalSize);
				}
				break;

			/*
			**	The sample is finished processing, but not necessarily finished playing.
			*/
			case _SAMPLE_PROCESSED:
				if (st->DataLength && st->Active) {
					_SOS_START_SAMPLE start;
					long dlength;

					dlength = st->DataLength;
					st->DataLength = 0;

					Audio_Mem_Set(&start, 0, sizeof(start));
					start.lpSamplePtr = (LPSTR)st->Buffer[st->Index];

					start.dwSampleSize = dlength-1;

					start.wSampleFlags = st->Flags;
					start.lpCallback = (void cdecl (far *)(unsigned int, unsigned int, unsigned int))&DigiCallback;
					start.wLoopCount = 0;
					if (st->IsScore) {
						start.wVolume = (st->Volume>>8) * LockedData.ScoreVolume;
						sosDIGISetSampleVolume(LockedData.DigiHandle, st->Handle, start.wVolume);
					} else {
						start.wVolume = (st->Volume>>8) * LockedData.SoundVolume;
						sosDIGISetSampleVolume(LockedData.DigiHandle, st->Handle, start.wVolume);
					}

					start.wChannel = st->Stereo;
					start.wSampleID = index+1;
					start.dwSamplePitchAdd = st->Pitch;
					st->Index ^= 1;

					if (st->Remainder || st->QueueBuffer || st->Callback || st->FilePending) {
						st->Service = TRUE;
						LockedData.ServiceSomething = TRUE;
					}

					sosDIGIContinueSample(LockedData.DigiHandle, st->Handle, &start);
				} else {

					/*
					**	This is necessary because Stop_Sample may screw things
					**	up, otherwise.  Can't rely on the _SAMPLE_DONE call.
					*/
					st->Active = FALSE;
					if (!st->IsScore) {
//						DPMI_Unlock(st->Original, st->OriginalSize);
					}

				}
				break;

			/*
			**	Sample is now looping (not used).
			*/
			case _SAMPLE_LOOPING:
				break;
		}
	}

}

void far HMI_TimerCallback(void)
{
}


/***************************************************************************
 * ADD_LONG_TO_POINTER -- Adds an offset to a ptr casted void              *
 *                                                                         *
 * INPUT:		void * ptr - the pointer to add to                          *
 *					long size  - the size to add to it									*
 *                                                                         *
 * OUTPUT:     void * ptr - the new location it will point to              *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/23/1995 PWG : Created.                                             *
 *=========================================================================*/

void *Audio_Add_Long_To_Pointer(void const *ptr, long size) 
{
 	return ((void *) ( (char const *) ptr + size));
}

/***************************************************************************
 * AUDIO_MEM_SET -- Quick see routine to set memory to a value             *
 *                                                                         *
 * INPUT:		void const *  - the memory that needs to be set             *
 *					unsigned char - the value to set the memory to					*
 *					long size     - how big an area to set								*
 *                                                                         *
 * OUTPUT:		none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/28/1995 PWG : Created.                                             *
 *=========================================================================*/
void Audio_Mem_Set(void const *ptr, unsigned char value, long size)
{
	unsigned char *temp = (unsigned char *)ptr;
	for (int lp = 0; lp < size; lp ++) {
		*temp++ = value;
	}
}
