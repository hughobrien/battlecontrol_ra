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

/* $Header: /CounterStrike/INTERPAL.CPP 1     3/03/97 10:24a Joe_bostic $ */
/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : INTERPAL.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : December 7th 1995                                            *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *  This module contains functions to allow use of old 320x200 animations on a 640x400 screen  *
 *                                                                                             *
 * Functions:                                                                                  *
 *  Read_Interpolation_Palette -- reads an interpolation palette table from disk               *
 *  Write_Interpolation_Palette -- writes an interpolation palette to disk                     *
 *  Create_Palette_Interpolation_Table -- build the palette interpolation table                *
 *  Increase_Palette_Luminance -- increase the contrast of a palette                           *
 *  Interpolate_2X_Scale -- Stretch a 320x200 graphic buffer into 640x400                      *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "FUNCTION.H"

BOOL	InterpolationPaletteChanged = FALSE;
extern "C" {
void __cdecl Asm_Interpolate (uint8_t * src_ptr ,
												uint8_t * dest_ptr ,
												int				lines ,
												int				src_width ,
												int				dest_width);

void __cdecl Asm_Interpolate_Line_Double (uint8_t * src_ptr ,
												uint8_t * dest_ptr ,
												int				lines ,
												int				src_width ,
												int				dest_width);

void __cdecl Asm_Interpolate_Line_Interpolate (uint8_t * src_ptr ,
												uint8_t * dest_ptr ,
												int				lines ,
												int				src_width ,
												int				dest_width);

}

#define SIZE_OF_PALETTE	256
extern "C"{
	uint8_t PaletteInterpolationTable[SIZE_OF_PALETTE][SIZE_OF_PALETTE];
	uint8_t * InterpolationPalette;
}



/***********************************************************************************************
 * Read_Interpolation_Palette -- reads an interpolation palette table from disk               *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    name of palette file                                                              *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/12/95 12:15PM ST : Created                                                            *
 *=============================================================================================*/

void Read_Interpolation_Palette (char const * palette_file_name)
{
	CCFileClass palette_file(palette_file_name);

	if (palette_file.Is_Available()) {
		palette_file.Open(READ);
		palette_file.Read(&PaletteInterpolationTable[0][0], 256*256);
		palette_file.Close();
		InterpolationPaletteChanged = FALSE;
	}
}


/***********************************************************************************************
 * Write_Interpolation_Palette -- writes an interpolation palette table to disk               *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    name of palette file                                                              *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/12/95 12:15PM ST : Created                                                            *
 *=============================================================================================*/

void Write_Interpolation_Palette (char const * palette_file_name)
{
	CCFileClass palette_file(palette_file_name);

	if (!palette_file.Is_Available()) {
		palette_file.Open(WRITE);
		palette_file.Write(&PaletteInterpolationTable[0][0], 256*256);
		palette_file.Close();
	}
}





/***************************************************************************
 * CREATE_PALETTE_INTERPOLATION_TABLE                                      *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/06/1995  MG : Created.                                             *
 *=========================================================================*/
void Create_Palette_Interpolation_Table( void )
{

//	Asm_Create_Palette_Interpolation_Table();

	#if (1)

	int 				i;
	int 				j;
	int 				p;
	uint8_t	* first_palette_ptr;
	uint8_t	* second_palette_ptr;
	uint8_t	* match_pal_ptr;
	int				first_r;
	int				first_g;
	int				first_b;
	int				second_r;
	int				second_g;
	int				second_b;
	int				diff_r;
	int				diff_g;
	int				diff_b;
	int				dest_r;
	int				dest_g;
	int				dest_b;
	int 				distance;
	int 				closest_distance;
	int 				index_of_closest_color;

	//
	// Create an interpolation table for the current palette.
	//
	first_palette_ptr = InterpolationPalette;
	for ( i = 0; i < SIZE_OF_PALETTE; i ++ ) {

		//
		// Get the first palette entry's RGB.
		//
		first_r = *first_palette_ptr;
		first_palette_ptr ++;
		first_g = *first_palette_ptr;
		first_palette_ptr ++;
		first_b = *first_palette_ptr;
		first_palette_ptr ++;

		second_palette_ptr = InterpolationPalette;
		for  ( j = 0; j < SIZE_OF_PALETTE; j ++ ) {
			//
			// Get the second palette entry's RGB.
			//
			second_r = *second_palette_ptr;
			second_palette_ptr ++;
			second_g = *second_palette_ptr;
			second_palette_ptr ++;
			second_b = *second_palette_ptr;
			second_palette_ptr ++;

			//
			// Now calculate the RGB halfway between the first and second colors.
			//
			dest_r = ( first_r + second_r ) >> 1;
			dest_g = ( first_g + second_g ) >> 1;
			dest_b = ( first_b + second_b ) >> 1;

			//
			// Now find the color in the palette that most closely matches the interpolated color.
			//
			index_of_closest_color = 0;
//			closest_distance = (256 * 256) * 3;
			closest_distance = 500000;
			match_pal_ptr = InterpolationPalette;
			for ( p = 0; p < SIZE_OF_PALETTE; p ++ ) {
				diff_r = ( ((int) (*match_pal_ptr)) - dest_r );
				match_pal_ptr ++;
				diff_g = ( ((int) (*match_pal_ptr)) - dest_g );
				match_pal_ptr ++;
				diff_b = ( ((int) (*match_pal_ptr)) - dest_b );
				match_pal_ptr ++;

				distance = ( diff_r * diff_r ) + ( diff_g * diff_g ) + ( diff_b * diff_b );
				if ( distance < closest_distance ) {
					closest_distance = distance;
					index_of_closest_color = p;
				}
			}

			PaletteInterpolationTable[ i ][ j ] = (uint8_t) index_of_closest_color;
		}
	}

	#endif
	InterpolationPaletteChanged = FALSE;
	return;

}









/***********************************************************************************************
 * Increase_Palette_Luminance -- increase contrast of colours in a palette                     *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to palette                                                                    *
 *           percentage increase of red                                                        *
 *           percentage increase of green                                                      *
 *           percentage increase of blue                                                       *
 *           cap value for colours                                                             *
 *                                                                                             *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/12/95 12:16PM ST : Created                                                            *
 *=============================================================================================*/

void Increase_Palette_Luminance (uint8_t * palette , int red_percentage , int green_percentage , int blue_percentage , int cap)
{

	unsigned	int	red;
	unsigned	int	green;
	unsigned	int	blue;
	for (int i=0 ; i<SIZE_OF_PALETTE*3 ; i+=3) {

		red 	= (unsigned)*(palette+i);
		green = (unsigned)*(palette+i+1);
		blue	= (unsigned)*(palette+i+2);

		red 	+= red*red_percentage/100;
		green	+= green*green_percentage/100;
		blue	+= blue*blue_percentage/100;

		red 	= MIN (cap, red);
		green	= MIN (cap, green);
		blue	= MIN (cap, blue);

		*(palette+i)	=(uint8_t)red;
		*(palette+i+1)	=(uint8_t)green;
		*(palette+i+2)	=(uint8_t)blue;

	}

}












int	CopyType	=0;

static uint8_t LineBuffer[640 * sizeof(uint32_t)];
static uint8_t TopLine[640 * sizeof(uint32_t)];
static uint8_t BottomLine[640 * sizeof(uint32_t)];

static void Interpolate_Single_Line(uint8_t * source_ptr, uint8_t * dest_ptr, int source_width)
{
	int source_index = 0;
	int pair_count = (source_width - 2) >> 1;

	while (pair_count--) {
		dest_ptr[0] = source_ptr[source_index];
		dest_ptr[1] = PaletteInterpolationTable[source_ptr[source_index + 1]][source_ptr[source_index]];
		dest_ptr[2] = source_ptr[source_index + 1];
		dest_ptr[3] = PaletteInterpolationTable[source_ptr[source_index + 2]][source_ptr[source_index + 1]];
		source_index += 2;
		dest_ptr += 4;
	}

	dest_ptr[0] = source_ptr[source_index];
	dest_ptr[1] = PaletteInterpolationTable[source_ptr[source_index + 1]][source_ptr[source_index]];
	dest_ptr[2] = source_ptr[source_index + 1];
	dest_ptr[3] = 0;
}

static void Interpolate_Between_Lines(uint8_t * source1, uint8_t * source2, uint8_t * destination, int source_width)
{
	int count = source_width * 2;

	while (count--) {
		*destination++ = PaletteInterpolationTable[*source2++][*source1++];
	}
}

extern "C" void __cdecl Asm_Interpolate(uint8_t * src_ptr, uint8_t * dest_ptr, int lines, int src_width, int dest_width)
{
	while (lines--) {
		Interpolate_Single_Line(src_ptr, dest_ptr, src_width);
		src_ptr += src_width;
		dest_ptr += dest_width;
	}
}

extern "C" void __cdecl Asm_Interpolate_Line_Double(uint8_t * src_ptr, uint8_t * dest_ptr, int lines, int src_width, int dest_width)
{
	int dest_stride = dest_width >> 1;

	while (lines--) {
		Interpolate_Single_Line(src_ptr, dest_ptr, src_width);
		Interpolate_Single_Line(src_ptr, LineBuffer, src_width);
		memcpy(dest_ptr + dest_stride, LineBuffer, src_width * 2);
		src_ptr += src_width;
		dest_ptr += dest_width;
	}
}

extern "C" void __cdecl Asm_Interpolate_Line_Interpolate(uint8_t * src_ptr, uint8_t * dest_ptr, int lines, int src_width, int dest_width)
{
	uint8_t * next_line = TopLine;
	uint8_t * last_line = BottomLine;
	int dest_stride = dest_width >> 1;

	Interpolate_Single_Line(src_ptr, next_line, src_width);
	uint8_t * swap_line = next_line;
	next_line = last_line;
	last_line = swap_line;
	src_ptr += src_width;
	lines--;

	while (lines--) {
		Interpolate_Single_Line(src_ptr, next_line, src_width);
		Interpolate_Between_Lines(last_line, next_line, LineBuffer, src_width);
		memcpy(dest_ptr, last_line, src_width * 2);
		dest_ptr += dest_stride;
		memcpy(dest_ptr, LineBuffer, src_width * 2);
		dest_ptr += dest_stride;
		src_ptr += src_width;
		swap_line = next_line;
		next_line = last_line;
		last_line = swap_line;
	}

	Interpolate_Single_Line(src_ptr, next_line, src_width);
	memcpy(dest_ptr, next_line, src_width * 2);
}

#ifdef WIN32
/***************************************************************************
 * INTERPOLATE_2X_SCALE                                                    *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/06/1995  MG : Created.                                             *
 *=========================================================================*/
void Interpolate_2X_Scale( GraphicBufferClass * source, GraphicViewPortClass * dest , char const * palette_file_name)
{
	uint8_t	* src_ptr;
	uint8_t	* dest_ptr;
	uint8_t	* last_dest_ptr;
	uint8_t	* end_of_source;
	int	src_width;
	int	dest_width;
//	int	width_counter;
	BOOL	source_locked = FALSE;
	BOOL	dest_locked = FALSE;


	/*
	**If a palette table exists on disk then read it in otherwise create it
	*/
	if (InterpolationPaletteChanged) {
		if (palette_file_name) {
			Read_Interpolation_Palette(palette_file_name);
		}
		if (InterpolationPaletteChanged) {
			Create_Palette_Interpolation_Table();
		}
	}

	/*
	** Write the palette table to disk so we don't have to create it again next time
	*/
	if (palette_file_name) {
		Write_Interpolation_Palette(palette_file_name);
	}
	if ( dest == &SeenBuff ) Hide_Mouse();

	Wait_Blit();

	/*
	** Lock video surfaces if required
	*/
	if (source->Get_IsDirectDraw()) {
		if (!source->Lock()) {
			if (dest == &SeenBuff) Show_Mouse();
			return;
		}
		source_locked = TRUE;
	}
	if (dest->Get_IsDirectDraw()) {
		if (!dest->Lock()) {
			if (source_locked) {
				source->Unlock();
			}
			if (dest == &SeenBuff) Show_Mouse();
			return;
		}
		dest_locked = TRUE;
	}


	//
	// Get pointers to the source and destination buffers.
	//
	src_ptr = (uint8_t *) source->Get_Offset();
	dest_ptr = (uint8_t *) dest->Get_Offset();
	end_of_source = src_ptr + ( source->Get_Width() * source->Get_Height() );

	//
	// Get width of source and dest buffers.
	//
	src_width = source->Get_Width();
	dest_width = 2*(dest->Get_Width() + dest->Get_XAdd() + dest->Get_Pitch());
	last_dest_ptr = dest_ptr;

	/*
	** Call the appropriate assembly language copy routine
	*/
#if (1)
	switch (CopyType) {
		case 0:
			Asm_Interpolate ( src_ptr , dest_ptr , source->Get_Height() , src_width , dest_width);
			break;

		case 1:
			Asm_Interpolate_Line_Double( src_ptr , dest_ptr , source->Get_Height() , src_width , dest_width);
			break;

		case 2:
			Asm_Interpolate_Line_Interpolate( src_ptr , dest_ptr , source->Get_Height() , src_width , dest_width);
			break;
	}
#endif

#if (0)
	//
	// Copy over the first pixel (upper left).
	//
	*dest_ptr = *src_ptr;
	src_ptr ++;
	dest_ptr ++;

	//
	// Scale copy.
	//
	width_counter = 0;
	while ( src_ptr < end_of_source ) {

		//
		// Blend this pixel with the one to the left and place this new color in the dest buffer.
		//
		*dest_ptr = PaletteInterpolationTable[ (*src_ptr) ][ (*( src_ptr - 1 )) ];
		dest_ptr ++;

		//
		// Now place the source pixel into the dest buffer.
		//
		*dest_ptr = *src_ptr;

		src_ptr ++;
		dest_ptr ++;

		width_counter ++;
		if ( width_counter == src_width ) {
			width_counter = 0;
			last_dest_ptr += dest_width;
			dest_ptr = last_dest_ptr;
		}
	}

#endif
	if (source_locked) source->Unlock();
	if (dest_locked) dest->Unlock();
	if (dest == &SeenBuff) Show_Mouse();

//BG	long *longptr = (long *)&PaletteInterpolationTable[0][0];
//BG	Mono_Printf("Clock cycles: %08x\n",*longptr);
}
#endif



