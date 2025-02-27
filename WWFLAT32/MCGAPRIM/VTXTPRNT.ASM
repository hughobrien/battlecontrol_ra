;
;	Command & Conquer Red Alert(tm)
;	Copyright 2025 Electronic Arts Inc.
;
;	This program is free software: you can redistribute it and/or modify
;	it under the terms of the GNU General Public License as published by
;	the Free Software Foundation, either version 3 of the License, or
;	(at your option) any later version.
;
;	This program is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU General Public License
;	along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

;***************************************************************************
;**      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : VTXTPRNT.ASM                             *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : January 17, 1995                         *
;*                                                                         *
;*                  Last Update : January 17, 1995   [PWG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Vesa_Print -- Prints a text string to a Vesa Viewport                 *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE "mcgaprim.inc"
INCLUDE "gbuffer.inc"


CODESEG


;***************************************************************************
;* VESA_PRINT -- Prints a text string to a Vesa Viewport                   *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/17/1995 PWG : Created.                                             *
;*=========================================================================*
	PROC	Vesa_Print C near
	ret
	ENDP	Vesa_Print


END