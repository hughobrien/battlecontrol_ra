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

; $Header: g:/library/wwlib32/misc/rcs/lcwuncmp.asm 1.1 1994/04/11 15:31:21 jeff_wilson Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Library routine                          *
;*                                                                         *
;*                    File Name : UNCOMP.ASM                               *
;*                                                                         *
;*                   Programmer : Christopher Yates                        *
;*                                                                         *
;*                  Last Update : 20 August, 1990   [CY]                   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*                                                                         *
; ULONG LCW_Uncompress(BYTE *source, BYTE *dest, ULONG length);		   *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL            LCW_Uncompress          :NEAR

CODESEG

; ----------------------------------------------------------------
;
; Here are prototypes for the routines defined within this module:
;
; ULONG LCW_Uncompress(BYTE *source, BYTE *dest, ULONG length);
;
; ----------------------------------------------------------------



PROC	LCW_Uncompress C near 

	USES ebx,ecx,edx,edi,esi
	
	ARG	source:DWORD 	   
	ARG	dest:DWORD
	ARG	length:DWORD
;LOCALS
	LOCAL a1stdest:DWORD
	LOCAL maxlen:DWORD
	LOCAL lastbyte:DWORD
	LOCAL lastcom:DWORD
	LOCAL lastcom1:DWORD


	mov	edi,[dest]
	mov	esi,[source]
	mov	edx,[length]

;
;
; uncompress data to the following codes in the format b = byte, w = word
; n = byte code pulled from compressed data
;   Bit field of n		command		description
; n=0xxxyyyy,yyyyyyyy		short run	back y bytes and run x+3
; n=10xxxxxx,n1,n2,...,nx+1	med length	copy the next x+1 bytes
; n=11xxxxxx,w1			med run		run x+3 bytes from offset w1
; n=11111111,w1,w2		long copy	copy w1 bytes from offset w2
; n=11111110,w1,b1		long run	run byte b1 for w1 bytes
; n=10000000			end		end of data reached
;

	mov	[a1stdest],edi
	add	edx,edi
	mov	[lastbyte],edx
	cld			; make sure all lod and sto are forward
	mov	ebx,esi		; save the source offset

??loop:
	mov	eax,[lastbyte]
	sub	eax,edi		; get the remaining byte to uncomp
	jz	short ??out		; were done
	
	mov	[maxlen],eax	; save for string commands
	mov	esi,ebx		; mov in the source index

	sub	eax,eax
	lodsb
	or	al,al		; see if its a short run
	js	short ??notshort
	
	mov	ah,al		; put rel offset high nibble in ah
	and	ah,0Fh		; only 4 bits count
	
	sub	ecx,ecx
	mov	cl,al		; put count nibble in ch
	shr	cl,4		; get run -3
	add	ecx,3		; get actual run length
	
	cmp	ecx,[maxlen]	; is it too big to fit?
	jbe	short ??rsok		; if not, its ok
	
	mov	ecx,[maxlen]	; if so, max it out so it dosen't overrun

??rsok:
	lodsb			; get rel offset low byte
	mov	ebx,esi		; save the source offset
	mov	esi,edi		; get the current dest
	sub	esi,eax		; get relative offset
	
	rep movsb

	jmp	??loop

??notshort:
	test	al,40h		; is it a length?
	jne	short ??notlength	; if not it could be med or long run
	
	cmp	al,80h		; is it the end?
	je	short ??out		; if so its over
	
	mov	cl,al		; put the byte in count register
	and	ecx,3Fh		; and off the extra bits
	
	cmp	ecx,[maxlen]	; is it too big to fit?
	jbe	short ??lenok		; if not, its ok
	
	mov	ecx,[maxlen]	; if so, max it out so it dosen't overrun

??lenok:
	rep movsb

	mov	ebx,esi		; save the source offset
	jmp	??loop

??out:
      	mov	eax,edi
	sub	eax,[a1stdest]
	jmp	short ??exit

??notlength:
	mov	cl,al		; get the entire code
	and	ecx,3Fh		; and off all but the size -3
	add	ecx,3		; add 3 for byte count
	
	cmp	al,0FEh
	jne	short ??notrunlength
	
	sub	eax,eax
	lodsw
	
	mov	ecx,eax
	
	sub	eax,eax
	lodsb
	
	mov	ebx,esi		; save the source offset
	cmp	ecx,[maxlen]	; is it too big to fit?
	jbe	short ??runlenok		; if not, its ok
	
	mov	ecx,[maxlen]	; if so, max it out so it dosen't overrun

??runlenok:
	rep stosb

	jmp	??loop

??notrunlength:
	cmp	al,0FFh		; is it a long run?
	jne	short ??notlong	; if not use the code as the size
	
	sub	eax,eax
	lodsw			; if so, get the size
	mov	ecx,eax		; put int the count byte

??notlong:
	lodsw			; get the rel index
	mov	ebx,esi		; save the source offset
	add	eax,[a1stdest]	; add in the first index
	mov	esi,eax		; use this as a source
	cmp	ecx,[maxlen]	; is it too big to fit?
	jbe	short ??runok		; if not, its ok
	
	mov	ecx,[maxlen]	; if so, max it out so it dosen't overrun

??runok:
	rep movsb

	jmp	??loop

??exit:
	mov	eax,edi
	mov	ebx,[dest]
	sub	eax,ebx
	
	ret

ENDP	LCW_Uncompress

;***********************************************************


	END
        
