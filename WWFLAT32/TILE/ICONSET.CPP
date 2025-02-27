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
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Library                                  *
 *                                                                         *
 *                    File Name : ICONSET.C                                *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : June 9, 1991                             *
 *                                                                         *
 *                  Last Update : September 15, 1993   [JLB]               *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Load_Icon_Set -- Loads an icons set and initializes it.               *
 *   Free_Icon_Set -- Frees allocations made by Load_Icon_Set().           *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

//#include	"function.h"
#include	<dos.h>
#include	<stdlib.h>
#include	<stdio.h>
#include	<mem.h>
#include	<wwstd.h>
#include	<file.h>
#include	<iff.h>

unsigned long Misc;

void * cdecl Load_Icon_Set(char const *filename, void *iconsetptr, long buffsize);
void cdecl Free_Icon_Set(void const *iconset);
long cdecl Get_Icon_Set_Size(void const *iconset);
int cdecl Get_Icon_Set_Width(void const *iconset);
int cdecl Get_Icon_Set_Height(void const *iconset);
void * cdecl Get_Icon_Set_Icondata(void const *iconset);
void * cdecl Get_Icon_Set_Trans(void const *iconset);
void * cdecl Get_Icon_Set_Remapdata(void const *iconset);
void * cdecl Get_Icon_Set_Palettedata(void const *iconset);
int cdecl Get_Icon_Set_Count(void const *iconset);
void * cdecl Get_Icon_Set_Map(void const *iconset);


//#define	ICON_PALETTE_BYTES	16
//#define	ICON_MAX					256

/***************************************************************************
**	The terrain is rendered by using icons.  These are the buffers that hold
**	the icon data, remap tables, and remap index arrays.
*/
//PRIVATE char *IconPalette = NULL;		// MCGA only.
//PRIVATE char *IconRemap = NULL;			// MCGA only.

#define	FORM_RPAL	MAKE_ID('R','P','A','L')
#define	FORM_RTBL	MAKE_ID('R','T','B','L')
#define	FORM_SSET	MAKE_ID('S','S','E','T')
#define	FORM_SINF	MAKE_ID('S','I','N','F')
#define	FORM_ICON	MAKE_ID('I','C','O','N')
#define	FORM_TRNS	MAKE_ID('T','R','N','S')
#define	FORM_MAP		MAKE_ID('M','A','P',' ')

/*
** This is the control structure at the start of a loaded icon set.  It must match
** the structure in WWLIB.I!  This structure MUST be a multiple of 16 bytes long.
*/
typedef struct {
	short	Width;			// Width of icons (pixels).
	short	Height;			// Height of icons (pixels).
	short	Count;			// Number of (logical) icons in this set.
//	BOOL	Allocated;		// Was this iconset allocated?
	short	Allocated;		// Was this iconset allocated?
	short	MapWidth;		// Width of map (in icons).
	short	MapHeight;		// Height of map (in icons).
	long	Size;				// Size of entire iconset memory block.
	long	Icons;			// Offset from buffer start to icon data.
	long	Palettes;		// Offset from buffer start to palette data.
	long	Remaps;			// Offset from buffer start to remap index data.
	long	TransFlag;		// Offset for transparency flag table.
	long	ColorMap;
	long	Map;				// Icon map offset (if present).
} IControl_Type;


/***************************************************************************
 * LOAD_ICON_SET -- Loads an icons set and initializes it.                 *
 *                                                                         *
 *    This routine will load an IFF icon set from disk.  It handles all    *
 *    of the necessary allocations.                                        *
 *                                                                         *
 * INPUT:   filename -- Name of the icon file.                             *
 *                                                                         *
 *          buffer   -- Pointer to paragraph aligned buffer to hold data.  *
 *                                                                         *
 *          size     -- Size of the buffer (in bytes).                     *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   In EEGA mode the iconset buffer will be free because the    *
 *             icons will have been transferred to card ram.               *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/21/1991 JLB : Created.                                             *
 *   07/01/1991 JLB : Determines icon size from file.                      *
 *   07/15/1991 JLB : Load and uncompress onto the same buffer.            *
 *   09/15/1993 JLB : Added EMS support.                                   *
 *=========================================================================*/
void * cdecl Load_Icon_Set(char const *filename, void *iconsetptr, long buffsize)
{
	int	fh;				// File handle of iconset.
	int	bytespericon;	// The number of bytes per icon.
	unsigned long	icons=0;			// Number of icons loaded.
	unsigned long	size;				// Size of the icon chunk (raw).

	unsigned long	transsize;
	void	*transptr=NULL;

	unsigned long	mapsize;				// Icon map chunk size.
	void	*mapptr=NULL;		// Icon map pointer.
	void	*returnptr=NULL;	// Iconset pointer returned by routine.
	BOOL	allocated=FALSE;	// Was the iconset block allocated?
	IControl_Type	*idata=NULL;	// Icon data loaded.
	long	id;				// ID of file openned.
	struct {
		char	Width;		// Width of icon in bytes.
		char	Height;		// Height of icon in bytes.
		char	Format;		// Graphic mode.
								//lint -esym(754,Format)
		char	Bitplanes;	// Number of bitplanes per icon.
	} sinf;

	/*
	**	Open the icon set for loading.  If it is not a legal icon set
	**	data file, then abort.
	*/
	fh = Open_Iff_File(filename);
	if (fh != ERROR) {
		Read_File(fh, &id, sizeof(long));
		if (id == FORM_ICON) {
		
			/*
			**	Determine the size of the icons and set up the graphic
			**	system accordingly.  Also get the sizes of the various
			**	data blocks that have to be loaded.
			*/
			Read_Iff_Chunk(fh, FORM_SINF, &sinf, sizeof(sinf));
			bytespericon = ((((int)sinf.Width)<<3)*(((int)sinf.Height)<<3)*(int)sinf.Bitplanes)>>3;

			size = Get_Iff_Chunk_Size(fh,FORM_SSET);
				transsize = Get_Iff_Chunk_Size(fh, FORM_TRNS);
			mapsize = Get_Iff_Chunk_Size(fh, FORM_MAP);
		
			/*
			**	Allocate the icon buffer if one isn't provided.  First try EMS and
			**	then try conventional RAM.
			*/
			allocated = FALSE;
			if (!iconsetptr) {
					buffsize = size + transsize + mapsize + sizeof(IControl_Type);

				Misc = buffsize;
				iconsetptr = Alloc(buffsize, MEM_NORMAL);
				allocated = (iconsetptr != NULL);
			}

			if (iconsetptr && (size+transsize+mapsize+sizeof(IControl_Type)) <= buffsize) {

				idata = (IControl_Type *)iconsetptr;

				memset(idata, 0, sizeof(IControl_Type));

				/*
				**	Initialize the iconset header structure.
				*/
				idata->Width = sinf.Width<<3;
				idata->Height = sinf.Height<<3;
				idata->Allocated = allocated;
				idata->Icons = sizeof(IControl_Type);
				idata->Map = idata->Icons + size;
					idata->TransFlag = idata->Map + mapsize;
				idata->Size = buffsize;

					{
						long	val;

						val = Read_Iff_Chunk(fh, FORM_SSET, Add_Long_To_Pointer(iconsetptr, sizeof(IControl_Type)), size);
						icons = (int)(val/(long)bytespericon);
						idata = (IControl_Type *)iconsetptr;				
					}

				if (mapsize) {
					icons = mapsize;
				}
				idata->Count = (short)icons;

				/*
				**	Limit buffer to only the size needed.  This is done AFTER loading of the
				**	raw icon data because it might have been compressed and thus need any
				**	extra space to perform an overlapped decompression.
				*/
					if (buffsize > size + transsize + mapsize + sizeof(IControl_Type)) {
						buffsize = size + transsize + mapsize + sizeof(IControl_Type);
					}

					transptr = Add_Long_To_Pointer(iconsetptr, idata->TransFlag);
					Read_Iff_Chunk(fh, FORM_TRNS, transptr, transsize);
					idata = (IControl_Type *)iconsetptr;				

				mapptr = Add_Long_To_Pointer(iconsetptr, idata->Map);
				Read_Iff_Chunk(fh, FORM_MAP, mapptr, mapsize);

				/*
				**	Let the graphic overlay know of the icon data.  This could involve
				**	translation and other data manipulations.
				*/
				//Init_Stamps(iconsetptr);

				returnptr = iconsetptr;
			}	
		}
		Close_Iff_File(fh);
	}

	return (returnptr);		// Return with icon pointer.
}


/***************************************************************************
 * FREE_ICON_SET -- Frees allocations made by Load_Icon_Set().             *
 *                                                                         *
 *    This routine is used to free up any allocations by Load_Icon_Set().  *
 *    Use this routine when a new icon set is to be loaded.                *
 *                                                                         *
 * INPUT:   none                                                           *
 *                                                                         *
 * OUTPUT:  none                                                           *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/21/1991 JLB : Created.                                             *
 *=========================================================================*/
void cdecl Free_Icon_Set(void const *iconset)
{
	IControl_Type	*icontrol;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		if (icontrol->Allocated) {
			Free((void *)iconset);
		}
	}
}


long cdecl Get_Icon_Set_Size(void const *iconset)
{
	IControl_Type	*icontrol;
	long				size=0;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		size = icontrol->Size;
	}
	return(size);
}


int cdecl Get_Icon_Set_Width(void const *iconset)
{
	IControl_Type	*icontrol;
	int				width=0;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		width = icontrol->Width;
	}
	return(width);
}


int cdecl Get_Icon_Set_Height(void const *iconset)
{
	IControl_Type	*icontrol;
	int				height=0;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		height = icontrol->Height;
	}
	return(height);
}


void * cdecl Get_Icon_Set_Icondata(void const *iconset)
{
	IControl_Type	*icontrol;
	void				*ptr=NULL;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		ptr = Add_Long_To_Pointer((void *)iconset, icontrol->Icons);
	}
	return(ptr);
}

void * cdecl Get_Icon_Set_Trans(void const *iconset)
{
	IControl_Type	*icontrol;
	void				*ptr=NULL;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		ptr = Add_Long_To_Pointer((void *)iconset, icontrol->TransFlag);
	}
	return(ptr);
}


int cdecl Get_Icon_Set_Count(void const *iconset)
{
	IControl_Type	*icontrol;
	int				count;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		count = icontrol->Count;
	}
	return(count);
}


void * cdecl Get_Icon_Set_Map(void const *iconset)
{
	IControl_Type	*icontrol;
	void				*ptr=NULL;

	icontrol = (IControl_Type *)iconset;
	if (icontrol) {
		ptr = Add_Long_To_Pointer((void *)iconset, icontrol->Map);
	}
	return(ptr);
}



