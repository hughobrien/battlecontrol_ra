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

; $Header: g:/library/wwlib32/misc/rcs/reverse.asm 1.3 1994/04/25 12:22:45 scott_bowen Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : LIBRARY                                  *
;*                                                                         *
;*                    File Name : REVERSE.ASM                              *
;*                                                                         *
;*                   Programmer : Christopher Yates                        *
;*                                                                         *
;*                  Last Update : April 20, 1994   [SKB]                   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*                                                                         *
; LONG Reverse_LONG(LONG number);                                          *
; WORD Reverse_WORD(WORD number);					   *
; LONG Swap_LONG(LONG number);
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL	 Reverse_WORD	:NEAR
GLOBAL	 Swap_LONG	:NEAR
GLOBAL	 Reverse_LONG	:NEAR

CODESEG


; ----------------------------------------------------------------
;
; Here are prototypes for the routines defined within this module:
;
; LONG Reverse_LONG(LONG number);
; WORD Reverse_WORD(WORD number);
; LONG Swap_LONG(LONG number);
;
; ----------------------------------------------------------------

;-----------------------------------------------------------------
;
; REVERSE_LONG
;
; LONG Reverse_LONG(LONG number);
;
;*
	PROC	Reverse_LONG C near
	ARG	number:DWORD

IF 1
	mov	eax,[DWORD PTR number]
	xchg	al,ah
	ror	eax,16
	xchg	al,ah
ELSE

	; This is old 16 bit code.
	mov	ax,[WORD PTR number]
	mov	dx,[WORD PTR number+2]
	xchg	ah,dl
	xchg	al,dh
ENDIF

	ret

	ENDP	Reverse_LONG

;-----------------------------------------------------------------

;-----------------------------------------------------------------
;
; REVERSE_WORD
;
; WORD Reverse_WORD(WORD number);
;
;*
	PROC	Reverse_WORD C near
	ARG	number:WORD

	mov	ax,[number]
	xchg	ah,al
	ret

	ENDP	Reverse_WORD

;-----------------------------------------------------------------


;-----------------------------------------------------------------
;
; SWAP_LONG
;
; LONG Swap_LONG(LONG number);
;
;*
	PROC	Swap_LONG C near
	ARG	number:DWORD

IF 1
	; 32 bit code.
    	mov	eax,[DWORD PTR number]
	ror	eax,16
ELSE
	; 16 bit code.
	mov	ax,[WORD PTR number+2]
	mov	dx,[WORD PTR number]
ENDIF

	ret


	ENDP	Swap_LONG

;-----------------------------------------------------------------

	END

