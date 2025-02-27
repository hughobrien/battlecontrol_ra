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

/* $Id: soundio.cpp 1.41 1994/06/20 15:01:39 joe_bostic Exp $ */
/***********************************************************************************************
 **             C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S             **
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Sound Library                                                *
 *                                                                                             *
 *                    File Name : SOUND.CPP                                                    *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : July 22, 1991                                                *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   File_Callback -- called to fill queue buffer for streaming sample     						  *
 *   Stream_Sample_Volume -- generic streaming sample playback init                            *
 *   Stream_Sample -- generic streaming sample playback init                                   *
 *   File_Stream_Sample -- Streams a sample directly from a file.                              *
 *   File_Stream_Preload -- Handles initial proload of a streaming samples                     *
 *   File_Stream_Sample_Volume -- Streams a sample directly from a file w/volume.              *
 *   Sound_Callback -- Audio driver callback function.                                         *
 *   Load_Sample -- Loads a digitized sample into RAM.                                         *
 *   Load_Sample_Into_Buffer -- Loads a digitized sample into a buffer.                        *
 *   Free_Sample -- Frees a previously loaded digitized sample.                                *
 *   Sound_End -- Uninitializes the sound driver.                                              *
 *   Stop_Sample -- Stops any currently playing sampled sound.                                 *
 *   Sample_Status -- Queries the current playing sample status (if any).                      *
 *   Sample_Length -- returns length of a sample in ticks                                      *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#pragma pack(4)
#include	"soundint.h"
#include <dos.h>
#include <mem.h>
#include <stdio.h>
#include <string.h>
#include	<direct.h>
#include	<stdlib.h>
#include	<wwmem.h>
#include	<keyboard.h>
#include	<file.h>
#include	<i86.h>
#include <timer.h>
#pragma pack(1)
#include "audio.h"
#pragma pack(4)

/*
**	If this is defined, then the streaming audio buffer will be filled
**	to maximum whenever filling is to occur. If undefined, it will fill
**	the streaming buffer in smaller chunks.
*/
#define	SIMPLE_FILLING

/*
**	This define (if present) enables the simple HMI hardware initialization process.
**	The process does not do auto detection, but rather takes the value directly from
**	the setup program and uses that as the sound card number.  The only "detection" it
**	does is to recognized the presence of the card and fetch its settings.
*/
#define	SIMPLE_HMI_INIT


/*
**	This is the rate that the maintenance callback gets called.
*/
#define	MAINTENANCE_RATE			60

/*
**	Size of the temporary buffer in XMS/EMS that direct file
**	streaming of sounds will allocate.
*/
#define	STREAM_BUFFER_SIZE		(128L*1024L)

/*
** Define the number of "StreamBufferSize" blocks that are read in
** at a minimum when the streaming sample load callback routine
** is called.  We will IGNORE loads that are less that this in order
** to avoid constant seeking on the CD.
*/
#define	STREAM_CUSHION_BLOCKS	4


/*
**	This is the maximum size that a sonarc block can be.  All sonarc blocks
**	must be either a multiple of this value or a binary root of this value.
*/
#define	LARGEST_SONARC_BLOCK		2048


//////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////// structs ///////////////////////////////////////

static _SOS_CAPABILITIES	DigiCaps;
static _SOS_HARDWARE 		DigiHardware;
static WORD 					MidiHandle = -1;
static unsigned int far		DigiTimer = 0;
static unsigned int far		MaintainTimer = 0;
static unsigned int far		SystemTimer = 0;
static int						Bits_Per_Sample;
VOID 								*DigiBuffer = NULL;
static BOOL 					StartingFileStream = FALSE;
short 							StreamLowImpact = FALSE;
MemoryFlagType 				StreamBufferFlag = MEM_NORMAL;
int 								Misc;
SFX_Type 						SoundType;
Sample_Type 					SampleType;
int								ReverseChannels = FALSE;

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/

static BOOL File_Callback(WORD id, WORD *odd, VOID **buffer, LONG *size);
static int cdecl Stream_Sample_Vol(void *buffer, long size, BOOL (*callback)(WORD id, WORD *odd, VOID **buffer, LONG *size), int volume, int handle);
static int cdecl Stream_Sample(void *buffer, long size, BOOL (*callback)(WORD id, WORD *odd, VOID **buffer, LONG *size));
/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/




/***************************************************************************
 * FILE_CALLBACK -- called to fill queue buffer for streaming sample       *
 *                                                                         *
 * This callback is called whenever the queue buffer playback has begun		*
 * and another buffer is needed for queuing up.  Returns TRUE if there		*
 * is more data to read from the file.													*
 *                                                                         *
 * INPUT:	WORD id			- the sample id number                          *
 *				WORD *odd		- which sample buffer to put info in				*
 *				VOID **buffer	- the buffer pointer to load data into				*
 *				LONG *size		- the amount to load										*
 *                                                                         *
 * OUTPUT:  BOOL true if more data to load, FALSE if done loading          *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/17/1995 PWG : Created.                                             *
 *=========================================================================*/
static BOOL File_Callback(WORD id, WORD *odd, VOID **buffer, LONG *size)
{
	SampleTrackerType	*st;		// Pointer to sample playback control struct.
	VOID					*ptr;		// Pointer to working portion of file buffer.

	if (id != -1) {
		st = &LockedData.SampleTracker[id];
		ptr = st->FileBuffer;
		if (ptr) {

			/*
			**	Move the next pending block into the primary 
			**	position.  Do this only if the queue pointer is
			**	null.
			*/
			st->DontTouch = TRUE;
			if (!*buffer && st->FilePending) {
				*buffer = Add_Long_To_Pointer(ptr, (long)(*odd % LockedData.StreamBufferCount)*(long)LockedData.StreamBufferSize);
				st->FilePending--;
				*odd = *odd + 1;
				if (!st->FilePending) {
					*size = st->FilePendingSize;
				} else {
					*size = LockedData.StreamBufferSize;
				}
			}
			st->DontTouch = FALSE;
			maintenance_callback();

			/*
			**	If the file handle is still valid, then read in the next
			**	block and add it to the next pending slot available.
			*/
			if (st->FilePending <
				(StreamLowImpact ? (LockedData.StreamBufferCount>>1) : ((LockedData.StreamBufferCount-3))) && st->FileHandle != ERROR) {


				int num_empty_buffers;

#ifdef SIMPLE_FILLING
				num_empty_buffers = (LockedData.StreamBufferCount-2) - st->FilePending;
#else

				//
				// num_empty_buffers will be from 1 to StreamBufferCount
				//
				if (StreamLowImpact) {
					num_empty_buffers = MIN((LockedData.StreamBufferCount >> 1)+STREAM_CUSHION_BLOCKS, (LockedData.StreamBufferCount - 2) - st->FilePending);
				}
				else {
					num_empty_buffers = (LockedData.StreamBufferCount - 2) - st->FilePending;
				}
#endif
				


				while (num_empty_buffers && st->FileHandle != ERROR) {
					int	tofill;
					long	psize;

					tofill = (*odd + st->FilePending) % LockedData.StreamBufferCount;

					ptr = Add_Long_To_Pointer(st->FileBuffer, (long)tofill * (long)LockedData.StreamBufferSize);
					psize = Read_File(st->FileHandle, ptr, LockedData.StreamBufferSize);

					/*
					**	If less than the requested amount of data was read, this
					**	indicates that the source file is exhausted.  Flag the source
					**	file as closed so that no further reading is attempted.
					*/
					if (psize != LockedData.StreamBufferSize) {
						Close_File(st->FileHandle);
						st->FileHandle = ERROR;
					}

					/*
					**	If any real data went into the pending buffer, then flag
					**	that this buffer is valid.
					*/
					if (psize) {
						st->DontTouch = TRUE;
						st->FilePendingSize = psize;
						st->FilePending++;
						st->DontTouch = FALSE;
						maintenance_callback();
					}
					num_empty_buffers--;
				}

				/*
				**	After filling all pending buffers, check to see if the queue buffer
				**	is empty.  If so, then assign the first available pending buffer to the
				**	queue.
				*/
				st->DontTouch = TRUE;
				if (!st->QueueBuffer && st->FilePending) {
					st->QueueBuffer = Add_Long_To_Pointer(st->FileBuffer, (long)(st->Odd%LockedData.StreamBufferCount)*(long)LockedData.StreamBufferSize);
					st->FilePending--;
					st->Odd++;
					if (!st->FilePending) {
						st->QueueSize = st->FilePendingSize;
					} else {
						st->QueueSize = LockedData.StreamBufferSize;
					}
				}
				st->DontTouch = FALSE;
				maintenance_callback();
			}

			/*
			**	If there are no more buffers that the callback routine
			**	can slot into the primary position, then signal that
			**	no furthur callbacks are needed.
			*/
			if (st->FilePending) {
				return(TRUE);
			}
		}
	}
	return(FALSE);
}

/***************************************************************************
 * STREAM_SAMPLE_VOLUME -- generic streaming sample playback init          *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/17/1995 PWG : Created.                                             *
 *=========================================================================*/
static int cdecl Stream_Sample_Vol(void *buffer, long size, BOOL (*callback)(WORD id, WORD *odd, VOID **buffer, LONG *size), int volume, int handle)
{
	int						playid=-1;	// Sample play ID.
	SampleTrackerType		*st;			// Working pointer to sample control structure.
	long						oldsize;		// Copy of original sound size.
	AUDHeaderType			header;

	if (buffer && size && LockedData.DigiHandle != -1) {

		/*
		**	Start the first section of the sound playing.
		*/
		Mem_Copy(buffer, &header, sizeof(header));
		oldsize = header.Size;
		header.Size = size-sizeof(header);
		Mem_Copy(&header, buffer, sizeof(header));
		playid = Play_Sample_Handle(buffer, 0xFF, volume, 0x0, handle);
		header.Size = oldsize;
		Mem_Copy(&header, buffer, sizeof(header));

		/*
		**	If the sample actually started playing, then flag this
		**	sample as a streaming type and signal for a callback
		**	to occur.
		*/
		if (playid != -1) {
			st = &LockedData.SampleTracker[playid];

			st->Callback = callback;
			st->Odd = 0;
		}
	}
	return (playid);
}

/***************************************************************************
 * STREAM_SAMPLE -- generic streaming sample playback init          			*
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/17/1995 PWG : Created.                                             *
 *=========================================================================*/
static int cdecl Stream_Sample(void *buffer, long size, BOOL (*callback)(WORD id, WORD *odd, VOID **buffer, LONG *size), int handle)
{
	return Stream_Sample_Vol(buffer, size, callback, 0xFF, handle);
}



/***********************************************************************************************
 * File_Stream_Sample -- Streams a sample directly from a file.                                *
 *                                                                                             *
 *    This will take the file specified and play it directly from disk.                        *
 *    It performs this by allocating a temporary buffer in XMS/EMS and                         *
 *    then keeping this buffer filled by the Sound_Callback() routine.                         *
 *                                                                                             *
 * INPUT:   filename -- The name of the file to play.                                          *
 *                                                                                             *
 * OUTPUT:  Returns the handle to the sound -- just like Play_Sample().                        *
 *                                                                                             *
 * WARNINGS:   The temporary buffer is allocated when this routine is                          *
 *             called and then freed when the sound is finished.  Keep                         *
 *             this in mind.                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
int File_Stream_Sample(char const *filename, BOOL real_time_start)
{
	return File_Stream_Sample_Vol(filename, 0xFF, real_time_start);
}

/***************************************************************************
 * FILE_STREAM_PRELOAD -- Handles initial proload of streaming samples     *
 *                                                                         *
 * This function is called before a sample which streams from disk is      *
 * started.  It can be called to either fill the buffer in small chunks		*
 * from the call back routine or to fill the entire buffer at once.  This	*
 * is wholely dependant on whether the Loading bit is set within the 		*
 * sample tracker.																			*
 *                                                                         *
 * INPUT:		LockedData.SampleTracker * to the header which tracks this samples     *
 *										 processing.											*
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/05/1995 PWG : Created.                                             *
 *=========================================================================*/

void File_Stream_Preload(int handle)
{
	SampleTrackerType	*st	= &LockedData.SampleTracker[handle];
	int	fh						= st->FileHandle;
	int 	maxnum				= (LockedData.StreamBufferCount >> 1) + STREAM_CUSHION_BLOCKS;
	void 	*buffer				= st->FileBuffer;
	int	num;

	/*
	** Figure just how much we need to load.  If we are doing the load in progress
	** then we will only load two blocks.
	*/
	if (st->Loading) {
		num = st->FilePending + 2;
		num = MIN(num, maxnum);
	} else {
		num = maxnum;
	}

	//printf("Before buffer load!\n");
	/*
	** Loop through the blocks and load up the number we need.
	*/
	for (int index = st->FilePending; index < num; index++) {
		long s = Read_File(fh, Add_Long_To_Pointer(buffer, (long)index * (long)LockedData.StreamBufferSize), LockedData.StreamBufferSize);
		//printf("Reading block of size %d Stream Buffer = %d\n");
		if (s) {
			st->FilePendingSize = s;
			st->FilePending++;
		}
		if (s < LockedData.StreamBufferSize) break;
	}

	/*
	** If the last block was incomplete (ie. it didn't completely fill the buffer) or
	** we have now filled up as much of the Streaming Buffer as we need to, then now is
	** the time to kick off the sample.
	*/
	if (st->FilePendingSize < LockedData.StreamBufferSize || index == maxnum) {
		//printf("Before Stream Sample Volume!\n");
		/*
		** Actually start the sample playing, and don't worry about the file callback
		** it won't be called for a while.
		*/
		{
			int old						= LockedData.SoundVolume;
			int size						= (st->FilePending == 1) ? st->FilePendingSize : LockedData.StreamBufferSize;
			LockedData.SoundVolume	= LockedData.ScoreVolume;

			StartingFileStream 		= TRUE;
			Stream_Sample_Vol(buffer, size, File_Callback, st->Volume, handle);
			StartingFileStream 		= FALSE;
			LockedData.SoundVolume 	= old;
		}
		//printf("After Stream Sample Volume!\n");
		/*
		** The Sample is finished loading (if it was loading in small pieces) so record that
		** so that it will now use the active logic in the file call back.
		*/
		st->Loading					= FALSE;

		/*
		** Decrement the file pending because the first block is already playing thanks
		** to the play sample call above.
		*/
		st->FilePending--;

		/*
		** If File pending is now a zero, then we only preloaded one block and there
		** is nothing more to play.  So clear the sample tracing structure of the
		** information it no longer needs.
		*/
		if (!st->FilePending) {
			st->Odd					= 0;
			st->QueueBuffer		= 0;
			st->QueueSize			= 0;
			st->FilePendingSize	= 0;
			st->Callback 			= NULL;
			Close_File(fh);
		} else {
			/*
			**	The QueueBuffer counts as an already played block so remove it from the total.
			** Note: We didn't remove it before because there might not have been one.
			*/
			st->FilePending--;

			/*
			** When we start loading we need to start past the first two blocks.  Why this
			** is called Odd, I haven't got the slightest.
			*/
			st->Odd 					= 2;

			/*
			** If the file pending size is less than the stream buffer, then the last block
			** we loaded was the last block period.  So close the file and reset the handle.
			*/
			if (st->FilePendingSize != LockedData.StreamBufferSize) {
				Close_File(fh);
				st->FileHandle = ERROR;
			}

			/*
			** The Queue buffer needs to point at the next block to be processed.  The size
			** of the queue is dependant on how many more blocks there are.
			*/
			st->QueueBuffer = Add_Long_To_Pointer(buffer, LockedData.StreamBufferSize);
			if (!st->FilePending) {
				st->QueueSize = st->FilePendingSize;
			} else {
				st->QueueSize = LockedData.StreamBufferSize;
			}
		}
	}
}
/***********************************************************************************************
 * File_Stream_Sample_Vol -- Streams a sample directly from a file.                            *
 *                                                                                             *
 *    This will take the file specified and play it directly from disk.                        *
 *    It performs this by allocating a temporary buffer in XMS/EMS and                         *
 *    then keeping this buffer filled by the Sound_Callback() routine.                         *
 *                                                                                             *
 * INPUT:   filename -- The name of the file to play.                                          *
 *                                                                                             *
 * OUTPUT:  Returns the handle to the sound -- just like Play_Sample().                        *
 *                                                                                             *
 * WARNINGS:   The temporary buffer is allocated when this routine is                          *
 *             called and then freed when the sound is finished.  Keep                         *
 *             this in mind.                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
int File_Stream_Sample_Vol(char const *filename, int volume, BOOL real_time_start)
{
	static VOID	*buffer = NULL;
	SampleTrackerType	*st;
	int	fh;
	int	handle = -1;
	long	size;
	int	index;

	if (LockedData.DigiHandle != -1 && filename && Find_File(filename)) {
		//printf("Before initialize memory!\n");
		/*
		**	Make sure all sample tracker structures point to the same
		**	upper memory buffer.  This allocation only occurs if at
		**	least one sample gets "streamed".
		*/
		if (!buffer) {
			buffer = Alloc(LockedData.StreamBufferSize * LockedData.StreamBufferCount, (MemoryFlagType)(StreamBufferFlag | MEM_TEMP | MEM_LOCK));
			for (index = 0; index < LockedData.MaxSamples; index++) {
				LockedData.SampleTracker[index].FileBuffer = buffer;
			}
		}

		/*
		** If after trying to allocate the buffer we still fail then
		** we can stream this sample.
		*/
		if (!buffer) return(-1);
		
		//printf("Before Open File!\n");
		/*
		** Lets see if we can sucessfully open up the file.  If we can't, 
		** then there is no point in going any farther.
		*/
		if ((fh = Open_File(filename, READ)) == -1) {
			return (-1);
		}

		//printf("Before Get Free Handle!\n");
		/*
		** Reserve a handle so that we can fill in the sample tracker
		** with the needed information.  If we dont get valid handle then
		** we might as well give up.
		*/
		if ((unsigned)(handle = Get_Free_Sample_Handle(0xFF)) >= LockedData.MaxSamples) {
			return(-1);
		}

		/*
		** Now lets get a pointer to the proper sample handler and start
		** our manipulations.
		*/ 
		st							= &LockedData.SampleTracker[handle];
		st->IsScore				= TRUE;
		st->FilePending		= 0;
		st->FilePendingSize	= 0;
		st->Loading				= real_time_start;
		st->Volume				= volume;
		st->FileHandle			= fh;
		/*
		** Now that we have setup our initial data properly, let load up
		** the beginning of the sample we intend to stream.
		*/
		//printf("Before Preload!\n");
		File_Stream_Preload(handle);
	}
	return (handle);
}

/***********************************************************************************************
 * Sound_Callback -- Audio driver callback function.                                           *
 *                                                                                             *
 *    Maintains the audio buffers.  This routine must be called at least                       *
 *    11 times per second or else audio glitches will occur.                                   *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   If this routine is not called often enough then audio                           *
 *             glitches will occur.                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
VOID cdecl __saveregs __loadds Sound_Callback(VOID)
{
	int					index;
	SampleTrackerType	*st;

	if (LockedData.DigiHandle != -1) {
		st = &LockedData.SampleTracker[0];
		for (index = 0; index < LockedData.MaxSamples; index++) {
			if (st->Loading) {
				File_Stream_Preload(index);
			} else {
				/*
				**	General service routine to handle moving small blocks from the
				**	source into the low RAM staging buffers.
				*/

				if (st->Active) {
			

					/*
					**	Special check to see if the sample is a fading one AND
					**	it has faded to silence, then stop it here.
					*/
					if (st->Reducer && !st->Volume) {
						Stop_Sample(index);
					} else {

						/*
						**	Fill the queuebuffer if it is currently empty
						**	and there is a callback function defined to fill it.
						**
						** PWG/CDY & CO: We should be down by at least two blocks
						**					  before we bother with this
						*/
						if ((!st->QueueBuffer || 
							(st->FileHandle != ERROR && st->FilePending < LockedData.StreamBufferCount-3)) && 
							st->Callback) {

							if (!st->Callback(index, &st->Odd, &st->QueueBuffer, &st->QueueSize)) {
								st->Callback = NULL;
							}
						}
					}

				} else {

					/*
					**	This catches the case where a streaming sample gets
					**	aborted prematurely because of failure to call the
					**	callback function frequently enough.  In this case, the
					**	sample will be flagged as inactive, but the file handle
					**	will not have been closed.
					*/
					if (st->FileHandle != ERROR) {
						Close_File(st->FileHandle);
						st->FileHandle = ERROR;
					}
				}
			}

			/*
			**	Advance to the next sample control structure.
			*/
			st++;
		}
	}
}


/***********************************************************************************************
 * Load_Sample -- Loads a digitized sample into RAM.                                           *
 *                                                                                             *
 *    This routine loads a digitized sample into RAM.                                          *
 *                                                                                             *
 * INPUT:   filename -- Name of the sound file to load.                                        *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the loaded sound file.  This pointer                     *
 *          is passed to Play_Sample when playback is desired.                                 *
 *                                                                                             *
 * WARNINGS:   If there is insufficient memory to load the sample, then                        *
 *             NULL will be returned.                                                          *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/17/1992 JLB : Created.                                                                 *
 *   01/06/1994 JLB : HMI version.                                                             *
 *=============================================================================================*/
VOID *Load_Sample(char const *filename)
{
	void *buffer = NULL;
	long	size;
	int	fh;

	if (LockedData.DigiHandle == -1 || !filename || !Find_File(filename)) {
		return (NULL);
	}

	fh = Open_File(filename, READ);
	if (fh != ERROR) {
		size = File_Size(fh)+sizeof(AUDHeaderType);
		buffer = Alloc(size, MEM_NORMAL);

		if (buffer) {
			Sample_Read(fh, buffer, size);
		}
		Close_File(fh);
		Misc = size;
	}
	return(buffer);
}


/***********************************************************************************************
 * Load_Sample_Into_Buffer -- Loads a digitized sample into a buffer.                          *
 *                                                                                             *
 *    This routine is used to load a digitized sample into a buffer                            *
 *    provided by the programmer.  This buffer can be in XMS or EMS.                           *
 *                                                                                             *
 * INPUT:   filename -- The filename to load.                                                  *
 *                                                                                             *
 *          buffer   -- Pointer to the buffer to load into.                                    *
 *                                                                                             *
 *          size     -- The size of the buffer to load into.                                   *
 *                                                                                             *
 * OUTPUT:  Returns the number of bytes actually used in the buffer.                           *
 *                                                                                             *
 * WARNINGS:   This routine will not overflow the buffer provided.  This                       *
 *             means that the buffer must be big enough to hold the data                       *
 *             or else the sound will be cut short.                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
long Load_Sample_Into_Buffer(char const *filename, void *buffer, long size)
{
	int	fh;

	/*
	**	Verify legality of parameters.
	*/
	if (!buffer || !size || LockedData.DigiHandle == -1 || !filename || !Find_File(filename)) {
		return (NULL);
	}

	fh = Open_File(filename, READ);
	if (fh != ERROR) {
		size = Sample_Read(fh, buffer, size);
		Close_File(fh);
	} else {
		return(0);
	}
	return(size);
}


/***********************************************************************************************
 * Sample_Read -- Reads sample data from an openned file.                                      *
 *                                                                                             *
 *    This routine reads a sample file.  It is presumed that the file is                       *
 *    already positioned at the start of the sample.  From this, it can                        *
 *    determine if it is a VOC or raw data and proceed accordingly.                            *
 *                                                                                             *
 * INPUT:   fh       -- File handle of already openned sample file.                            *
 *                                                                                             *
 *          buffer   -- Pointer to the buffer to load data into.                               *
 *                                                                                             *
 *          size     -- The size of the buffer.                                                *
 *                                                                                             *
 * OUTPUT:  Returns the number of bytes actually used in the buffer.                           *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
long Sample_Read(int fh, void *buffer, long size)
{

	AUDHeaderType	RawHeader;
	VOID	*outbuffer;					// Pointer to start of raw data.
	long	actual_bytes_read;		// Actual bytes read in, including header

/*
	Conversion formula for TCrate and Hz rate.

	TC = 256 - 1m/rate
	rate = 1m / (256-TC)
*/

	if (!buffer || fh == ERROR || size <= sizeof(RawHeader)) return(NULL);
	size -= sizeof(RawHeader);
	outbuffer = Add_Long_To_Pointer(buffer, sizeof(RawHeader));

				actual_bytes_read = 
					Read_File(fh, &RawHeader, sizeof(RawHeader));

				actual_bytes_read +=
					Read_File(fh, outbuffer, MIN(size, RawHeader.Size));


	Mem_Copy(&RawHeader, buffer, sizeof(RawHeader));
	return(actual_bytes_read);
}


/***********************************************************************************************
 * Free_Sample -- Frees a previously loaded digitized sample.                                  *
 *                                                                                             *
 *    Use this routine to free the memory allocated by a previous call to                      *
 *    Load_Sample.                                                                             *
 *                                                                                             *
 * INPUT:   sample   -- Pointer to the sample to be freed.                                     *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/17/1992 JLB : Created.                                                                 *
 *=============================================================================================*/
VOID Free_Sample(VOID const *sample)
{
	if (sample) Free((void *)sample);
}

BOOL Sound_Init(int sfx, int score, int sample, RateType rate, int bits_per_sample, int max_samples, int reverse_channels)
{
	return Audio_Init(sample, -1, -1, -1, rate, bits_per_sample, max_samples, reverse_channels);
}

BOOL Audio_Init(int sample, int address, int inter, int dma, RateType rate, int bits_per_sample, int max_samples, int reverse_channels)
{
	int					error;	// Function error return code.
	unsigned int 		port;
	int					index;
	_SOS_INIT_DRIVER	init;		// Driver init structure.

	Init_Locked_Data();
	memset(&LockedData.SampleTracker[0], 0, sizeof(LockedData.SampleTracker));
	LockedData.Rate = rate;

	Bits_Per_Sample = bits_per_sample;

	sosTIMERInitSystem(_TIMER_DOS_RATE, _SOS_DEBUG_NORMAL);

	if (TimerSystemOn) {
		sosTIMERRegisterEvent(60, &Timer_Interrupt_Func, &SystemTimer);
		TickCount.Start();
	} else
		sosTIMERRegisterEvent(60, &HMI_TimerCallback, &SystemTimer);

	/*
	**	Special code to handle the HMI problem with running under Windows.
	*/
	if (/*Operating_System() != OS_DOS ||*/ sample == SAMPLE_NONE) {
		return(FALSE);
	}

	while (sample) {

#ifdef SIMPLE_HMI_INIT

		if (address == -1 || inter == -1 || dma == -1) {
			error = sosDIGIDetectInit((LPSTR)NULL);
			if (error) {
				printf("Cannot initialize detection system (%d).\n", error);
				Get_Key();
				break;
			}

			error = sosDIGIDetectFindHardware(sample, &DigiCaps, &port);
			if (error) {
				printf("Cannot find sound card specified.\n");
				Get_Key();
				break;
			}

			/*
			** Handle the override for Address, Interrupt, and DMA settings.
			*/
			error = sosDIGIDetectGetSettings(&DigiHardware);
			sosDIGIDetectUnInit();
			if (error) {
				printf("Cannot get sound card settings.\n");
				Get_Key();
				break;
			}
		} else {
		 	DigiHardware.wPort = address;
			DigiHardware.wIRQ = inter;
			DigiHardware.wDMA = dma;
		}
#endif

		/*
		**	Initialize the digi-system and driver.
		*/
		sosDIGIInitSystem((LPSTR)NULL, _SOS_DEBUG_NORMAL);
		init.wBufferSize		= 1024*8;				// Specify the DMA buf size
		init.lpBuffer			= (LPSTR)NULL;
		init.wAllocateBuffer = TRUE;
		init.wSampleRate		= rate;					// Sample playback rate.
		init.wParam				= 19;
		init.dwParam			= 0;
		init.lpFillHandler	= NULL;
		init.lpDriverMemory	= (LPSTR)NULL;
		init.lpTimerMemory	= (LPSTR)NULL;
		init.wTimerID			= _SOS_NORMAL_TIMER;
 		
		error = 0;
		error = sosDIGIInitDriver( (int)sample, &DigiHardware, &init, &LockedData.DigiHandle);
		if (error) {
			printf("Unable to initialize the sound driver.\n");
			Get_Key();
			break;
		}

		error = 0;


		if (sample >= _GUS_8_MONO && sample <= _GUS_16_ST) {
			error = sosTIMERRegisterEvent(120, init.lpFillHandler, &DigiTimer);
		} else {
			error = sosTIMERRegisterEvent(60, init.lpFillHandler, &DigiTimer);
		}
		if (error) {
			printf("Unable to regiser the fill handler.\n");
			Get_Key();
			sosDIGIUnInitDriver(LockedData.DigiHandle, TRUE, TRUE);
			LockedData.DigiHandle = -1;
			break;
		}

		/*
		**	Allocate a decompression buffer equal to the size of a SONARC frame
		**	block.
		*/
		LockedData.UncompBuffer = Alloc(LARGEST_SONARC_BLOCK + 50, (MemoryFlagType)(MEM_NORMAL|MEM_CLEAR|MEM_LOCK));
		LockedData.MaxSamples	= max_samples;

		/*
		**	Allocate private staging buffers for double buffering sound into HMI
		**	driver.
		*/
		DigiBuffer = Alloc(2048+(((LONG)LockedData.MaxSamples*2) * (LONG)(SFX_MINI_STAGE_BUFFER_SIZE+SONARC_MARGIN)), (MemoryFlagType)(MEM_NORMAL|MEM_CLEAR|MEM_LOCK));
		for (index = 0; index < LockedData.MaxSamples; index++) {
			LockedData.SampleTracker[index].Buffer[0] = Add_Long_To_Pointer(DigiBuffer, ((LONG)index*2) * (LONG)(SFX_MINI_STAGE_BUFFER_SIZE+SONARC_MARGIN));
			LockedData.SampleTracker[index].Buffer[1] = Add_Long_To_Pointer(DigiBuffer, ((LONG)index*2+1) * (LONG)(SFX_MINI_STAGE_BUFFER_SIZE+SONARC_MARGIN));
			LockedData.SampleTracker[index].FileHandle = ERROR;
			LockedData.SampleTracker[index].QueueBuffer = NULL;
		}
		error = sosTIMERRegisterEvent(MAINTENANCE_RATE, (void (__far *)(void))maintenance_callback, &MaintainTimer);
		if (error) {
			printf("Unable to initialize the maintenance callback.\n");
			Get_Key();
			sosTIMERRemoveEvent(DigiTimer);
			sosDIGIUnInitDriver(LockedData.DigiHandle, TRUE, TRUE);
			LockedData.DigiHandle = -1;
			break;
		}
		SoundType = (SFX_Type)sample;
		SampleType = (Sample_Type)sample;
		ReverseChannels = reverse_channels;

		break;
	}

	return(TRUE);
}


/***********************************************************************************************
 * Sound_End -- Uninitializes the sound driver.                                                *
 *                                                                                             *
 *    This routine will uninitialize the sound driver (if any was                              *
 *    installed).  This routine must be called at program termination                          *
 *    time.                                                                                    *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   07/23/1991 JLB : Created.                                                                 *
 *=============================================================================================*/
VOID Sound_End(VOID)
{

	if (LockedData.DigiHandle != -1) {
		sosTIMERRemoveEvent(DigiTimer);
		sosTIMERRemoveEvent(MaintainTimer);
		sosDIGIUnInitDriver(LockedData.DigiHandle, TRUE, TRUE);
		sosDIGIUnInitSystem();
		LockedData.DigiHandle = -1;
	}
	if (DigiBuffer) {
		Free(DigiBuffer);
		DigiBuffer = 0;
	}
	if (LockedData.UncompBuffer) {
		Free(LockedData.UncompBuffer);
		LockedData.UncompBuffer = 0;
	}
	sosTIMERRemoveEvent(SystemTimer);
	sosTIMERUnInitSystem(0);
	Unlock_Locked_Data();
}




/***********************************************************************************************
 * Stop_Sample -- Stops any currently playing sampled sound.                                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:                                                                                      *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/02/1992 JLB : Created.                                                                 *
 *=============================================================================================*/
VOID Stop_Sample(int handle)
{
	if (LockedData.DigiHandle != -1 && (unsigned)handle < LockedData.MaxSamples) {


		if (LockedData.SampleTracker[handle].Active || LockedData.SampleTracker[handle].Loading) {

			
			LockedData.SampleTracker[handle].Active = FALSE;
			if (!LockedData.SampleTracker[handle].IsScore) {
				DPMI_Unlock(LockedData.SampleTracker[handle].Original, LockedData.SampleTracker[handle].OriginalSize);
				LockedData.SampleTracker[handle].Original = NULL;
			}
			LockedData.SampleTracker[handle].Priority = 0;

			/*
			**	Stop the sample if it is playing.
			*/
			if (!LockedData.SampleTracker[handle].Loading) {
				sosDIGIStopSample(LockedData.DigiHandle, LockedData.SampleTracker[handle].Handle);
			}
			LockedData.SampleTracker[handle].Loading = FALSE;

			/*
			**	If this is a streaming sample, then close the source file.
			*/
			if (LockedData.SampleTracker[handle].FileHandle != ERROR) {
				Close_File(LockedData.SampleTracker[handle].FileHandle);
				LockedData.SampleTracker[handle].FileHandle = ERROR;
			}

			LockedData.SampleTracker[handle].QueueBuffer = NULL;
		}
	}
}


/***********************************************************************************************
 * Sample_Status -- Queries the current playing sample status (if any).                        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:                                                                                      *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/02/1992 JLB : Created.                                                                 *
 *=============================================================================================*/
BOOL Sample_Status(int handle)
{
	/*
	** If its an invalid handle or we do not have a sound driver then
	** the sample in question is not playing.
	*/
	if (LockedData.DigiHandle == -1 || (unsigned)handle >= LockedData.MaxSamples) return(FALSE);
	/*
	** If the sample is loading, then for all intents and purposes the
	** sample is playing.
	*/
	if (LockedData.SampleTracker[handle].Loading) return(TRUE);
	/* 
	** If the sample is not active, then it is not playing
	*/
	if (!LockedData.SampleTracker[handle].Active) return(FALSE);
	/*
	** If we made it this far, then the Sample is still playing if sos says
	** that it is.
	*/
	return (!sosDIGISampleDone(LockedData.DigiHandle, LockedData.SampleTracker[handle].Handle));
}


BOOL Is_Sample_Playing(void const * sample)
{
	int index;

	if (!sample) return FALSE;
	for (index = 0; index < LockedData.MaxSamples; index++) {
		if (LockedData.SampleTracker[index].Original == sample && Sample_Status(index)) {
			return (TRUE);
		}
	}
	return (FALSE);
}


VOID Stop_Sample_Playing(void const * sample)
{
	int index;

	if (sample) {
		for (index = 0; index < LockedData.MaxSamples; index++) {
			if (LockedData.SampleTracker[index].Original == sample) {
				Stop_Sample(index);
				break;
			}
		}
	}
}
int Get_Free_Sample_Handle(int priority)
{
	int	id;

	/*
	**	Find a free SFX holding buffer slot.
	*/
	for (id = LockedData.MaxSamples - 1; id >= 0; id--) {
		if (!LockedData.SampleTracker[id].Active && !LockedData.SampleTracker[id].Loading) {
			if (!StartingFileStream && LockedData.SampleTracker[id].IsScore) {
				StartingFileStream = TRUE;	// Ensures only one channel is kept free for scores.
				continue;
			}
			break;
		}
	}

	if (id < 0) {
		for (id = 0; id < LockedData.MaxSamples; id++) {
			if (LockedData.SampleTracker[id].Priority <= priority) break;
		}
		if (id == LockedData.MaxSamples) {
			return(-1);		// Cannot play!
		}
		Stop_Sample(id);							// This sample gets clobbered.
	}
	if (id == -1) {
		return -1;
	}
	if (LockedData.SampleTracker[id].FileHandle != ERROR) {
		Close_File(LockedData.SampleTracker[id].FileHandle);
		LockedData.SampleTracker[id].FileHandle = ERROR;
	}
	if (LockedData.SampleTracker[id].Original && !LockedData.SampleTracker[id].IsScore) {
		DPMI_Unlock(LockedData.SampleTracker[id].Original, LockedData.SampleTracker[id].OriginalSize);
		LockedData.SampleTracker[id].Original = NULL;
	}
	LockedData.SampleTracker[id].IsScore = FALSE;
	return(id);
}

int Play_Sample(void const *sample, int priority, int volume, signed short panloc)
{
	return(Play_Sample_Handle(sample, priority, volume, panloc, Get_Free_Sample_Handle(priority)));
}
/***********************************************************************************************
 * Play_Sample_Vol -- Plays a digitized sample.                                                *
 *                                                                                             *
 *    Use this routine to play a previously loaded digitized sample.                           *
 *                                                                                             *
 * INPUT:   sample   -- Sample pointer as returned from Load_Sample.                           *
 *                                                                                             *
 *          volume   -- The volume to play (0..255 with 255=loudest).                          *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/17/1992 JLB : Created.                                                                 *
 *   05/24/1992 JLB : Volume support -- Soundblaster Pro                                       *
 *   04/22/1994 JLB : Multiple sample playback rates.                                          *
 *=============================================================================================*/
int Play_Sample_Handle(void const *sample, int priority, int volume, signed short panloc, int id)
{
	AUDHeaderType			RawHeader;
	_SOS_START_SAMPLE 	start;
	SampleTrackerType		*st=NULL;	// Working pointer to sample tracker structure.

	if (!sample || LockedData.DigiHandle == -1) {
		return(-1);
	}

	if (id == -1) {
		return -1;
	}

	/*
	**	Fetch the control bytes from the start of the sample data.
	*/
	Mem_Copy((void *)sample, (void *)&RawHeader, sizeof(RawHeader));

	/*
	**	Prepare the sample tracker structure for processing of this
	**	sample.  Fill the structure with data that can be determined
	**	before the sample is started.
	*/
	st = &LockedData.SampleTracker[id];
	st->Compression	= (SCompressType) ((unsigned char)RawHeader.Compression);
	st->Original		= sample;
	st->OriginalSize	= RawHeader.Size + sizeof(RawHeader);
	if (!st->IsScore) {
		DPMI_Lock(st->Original, st->OriginalSize);
	}
	st->Priority		= priority;
	st->DontTouch		= FALSE;
	st->Odd				= 0;
	st->Reducer			= 0;
	st->Restart			= FALSE;
	st->QueueBuffer	= NULL;
	st->QueueSize		= NULL;
	st->TrailerLen 	= 0;
	st->Remainder		= RawHeader.Size;
	st->Source			= Add_Long_To_Pointer((void *)sample, sizeof(RawHeader));
	st->Service			= FALSE;

	/*
 	** If the code in question using HMI based compression then we need
	** to set up for uncompressing it.
	*/
	if (st->Compression == SCOMP_SOS) {
		st->sosinfo.wChannels	 = (RawHeader.Flags & AUD_FLAG_STEREO) ? 2  : 1;
		st->sosinfo.wBitSize		 = (RawHeader.Flags & AUD_FLAG_16BIT)  ? 16 : 8;
		st->sosinfo.dwCompSize	 = RawHeader.Size;
   	st->sosinfo.dwUnCompSize = RawHeader.Size * ( st->sosinfo.wBitSize / 4 );
	   sosCODECInitStream(&st->sosinfo);
	}

	/*
	**	Fill in one or both staging buffers if possible.
	*/
	_disable();
//	Disable_Timer_Interrupt();
	if (SFX_MINI_STAGE_BUFFER_SIZE == 
					Sample_Copy(st,
									&st->Source, 
									&st->Remainder, 
									&st->QueueBuffer, 
									&st->QueueSize, 
									st->Buffer[0], 
									SFX_MINI_STAGE_BUFFER_SIZE, 
									st->Compression, 
									&st->Trailer[0], 
									&st->TrailerLen)) {

		st->DataLength = Sample_Copy(st,
										&st->Source, 
										&st->Remainder, 
										&st->QueueBuffer, 
										&st->QueueSize, 
										st->Buffer[1], 
										SFX_MINI_STAGE_BUFFER_SIZE, 
										st->Compression, 
										&st->Trailer[0], 
										&st->TrailerLen);
		st->Index = 1;
	} else {
		st->Index = 0;
		st->DataLength = 0;
	}
	_enable();
//	Enable_Timer_Interrupt();

	/*
	**	Fill in the HMI start sample structure.
	*/
	memset(&start, 0, sizeof(start));

	start.lpSamplePtr = (LPSTR)st->Buffer[0];
	if (st->Index == 1) {
		start.dwSampleSize = SFX_MINI_STAGE_BUFFER_SIZE-1;
	} else {
		start.dwSampleSize = st->DataLength-1;
	}
	start.lpCallback	= (void cdecl (far *)(unsigned int, unsigned int, unsigned int))&DigiCallback;
	start.wLoopCount	= 0;
	start.wSampleID	= id;

	/*
	**	Adjust pitch shifting as necessary so that lower playback
	**	samples can be supported.
	*/
	if (RawHeader.Rate != LockedData.Rate) {
		ldiv_t	result;

		result						= ldiv((long)RawHeader.Rate, LockedData.Rate);
		start.dwSamplePitchAdd	= (long)MAKE_LONG((short)result.quot, (short)(((long)result.rem * 0x10000L) / LockedData.Rate));
		start.wSampleFlags 	  |= _PITCH_SHIFT;
	}

	/*
	**	Sample translation flag.
	*/

	if (RawHeader.Flags & AUD_FLAG_16BIT) {
		if (Bits_Per_Sample == 8) {
			start.wSampleFlags 	  |= _TRANSLATE16TO8;
		}
	} else {
		if (Bits_Per_Sample == 16) {
			start.wSampleFlags 	  |= _TRANSLATE8TO16;
		}
	}

	/*
	**	Sample stereo flag.
	*/
	if (RawHeader.Flags & AUD_FLAG_STEREO) {
		start.wChannel 			= _INTERLEAVED;
		start.wSampleFlags 	  |= _STEREOTOMONO;
	} else {
		start.wChannel 			= _CENTER_CHANNEL;
	}

	/*
	**	Sample volume control flags.  Always give it volume control because
	**	if not, then future volume control is either ignored or stops the
	**	sample.
	*/
	st->Volume 						= volume << 7;
	start.wVolume					= (st->Volume >> 8) * LockedData.SoundVolume;
	start.wSampleFlags  		  |= _VOLUME;
	
	/*
	** If we have defined a panning location for the sound driver than
	** take care of it here.  Panning will only work with a stereo driver
	** and only if the sample is played _CENTER_CHANNEL.
	*/
	if ((panloc != 0x0) && (!(RawHeader.Flags & AUD_FLAG_STEREO))) {
		start.wChannel 			= _CENTER_CHANNEL;
		panloc 						= ((ReverseChannels) ? ((-panloc) + 0x8000) : ((panloc) + 0x8000));
		start.wSampleFlags 	  |= _PANNING;
		start.wSamplePanLocation= panloc;
	}

	st->Stereo 	= start.wChannel;
	st->Pitch 	= start.dwSamplePitchAdd;
	st->Flags 	= start.wSampleFlags;

	/*
	**	Start the sample playing now.
	*/
	_disable();		// NEW
//	Disable_Timer_Interrupt();
	st->Handle = sosDIGIStartSample(LockedData.DigiHandle, &start);
	if (st->Handle == -1) {
		id = -1;
	} else {

		/*
		**	Fill in the sample tracker structure with those values that are
		**	determined AFTER the sample starts.
		*/
		st->Active = TRUE;
	}
	_enable();			// NEW
//	Enable_Timer_Interrupt();

	return(id);
}


int Set_Sound_Vol(int volume)
{
	int old;
	old = LockedData.SoundVolume;
	LockedData.SoundVolume = volume & 0xFF;
	return(old);
}


int Set_Score_Vol(int volume)
{
	int old;
	old = LockedData.ScoreVolume;
	LockedData.ScoreVolume = volume & 0xFF;
	return(old);
}


VOID Fade_Sample(int handle, int ticks)
{
	if (Sample_Status(handle)) {
		if (!ticks || LockedData.SampleTracker[handle].Loading) {
			Stop_Sample(handle);
		} else {
			SampleTrackerType * st;

			st = &LockedData.SampleTracker[handle];
			st->Reducer = (st->Volume / ticks)+1;
		}
	}
}
int Get_Digi_Handle(void)
{
	return(LockedData.DigiHandle);
}

/***************************************************************************
 * SAMPLE_LENGTH -- returns length of a sample in ticks                    *
 *                                                                         *
 * INPUT:		void const *sample - pointer to the sample to get length    *
 *											   of.												*
 *                                                                         *
 * OUTPUT:		long   				 - length of the sample in ticks (60/sec) *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/05/1995 PWG : Created.                                             *
 *=========================================================================*/
long Sample_Length(void const *sample)
{
	AUDHeaderType			RawHeader;

	if (!sample) return(0);

	Mem_Copy((void *)sample, (void *)&RawHeader, sizeof(RawHeader));

	long time = RawHeader.UncompSize;

	/*
	** If the sample is a 16 bit sample, then it will take only half
	** as long to play.
	*/
	if (RawHeader.Flags & AUD_FLAG_16BIT) {
		time >>= 1;
	}

	/*
	** If the sample is a stereo sample, then it will take only half
	** as long to play.
	*/
	if (RawHeader.Flags & AUD_FLAG_STEREO) {
		time >>= 1;
	}

	if (RawHeader.Rate/60) {
		time /= (RawHeader.Rate/60);
	}
	return(time);
}
