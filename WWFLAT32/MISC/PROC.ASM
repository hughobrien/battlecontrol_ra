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

; $Header: g:/library/wwlib32/system/rcs/opsys.asm 1.1 1994/04/18 09:14:12 jeff_wilson Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Operating System Flags                   *
;*                                                                         *
;*                    File Name : OPSYS.ASM                                *
;*                                                                         *
;*                   Programmer : Scott Bowen                              *
;*                                                                         *
;*                   Start Date : January 26, 1993                         *
;*                                                                         *
;*                  Last Update : January 26, 1993   [SB]                  *
;*                                                                         *
;* Updated to 32bit protected mode JAW					   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Operating_System -- Determines what the operating system is.          *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT

GLOBAL             Get_CPU		    :NEAR


DATASEG

OperatingSystem	dw	0


CODESEG

;***************************************************************************
;* Operating_System -- Determines what the operating system is.            *
;*                                                                         *
;* INPUT:   NONE.                                                          *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/26/1993  SB : Created.                                             *
;*=========================================================================*
	PROC	Get_CPU C near 
	USES	ebx,ecx,edx,es,edi
IF 0	
	xor	eax,eax      	 	
        mov     ax,1
        pushf
        pop     bx
        and     bh,0fh
        push    bx
        popf
        pushf
        pop     cx
        and     ch,0f0h
        cmp     ch,0f0h
        je      @@1                     ;8086 or below 80286

        inc     ax
        or      bh,0f0h
        push    bx
        popf
        pushf
        pop     cx
        and     ch,0f0h
        je      @@1                     ;80286
ENDIF
        mov	eax,3
        mov     ebx,esp
        and     esp,0fffffffch
        pushfd
        pop     edx
        mov     ecx,edx
        xor     edx,000040000h
        push    edx
        popfd
        pushfd
        pop     edx
        push    ecx
        popfd
        xor     edx,ecx
        and     edx,000040000h          ;test alignment check bit
        mov     esp,ebx
        jz      @@1                     ;80386
        ;.486
        inc     eax
        pushfd
        pop     edx
        mov     ecx,edx
        xor     edx,000200000h
        push    edx
        popfd
        pushfd
        pop     edx
        push    ecx
        popfd
        xor     edx,ecx                 ;test id bit
        jz      @@1                     ;80486
P586
        mov     eax,1
        ;.586 or higher, cpuid returns cpu generation number in ax bits 8-11
        cpuid
        and     eax,0f00h
        shr     eax,8
P386
@@1:    ret

ENDP	Get_CPU



;----------------------------------------------------------------------------

END

