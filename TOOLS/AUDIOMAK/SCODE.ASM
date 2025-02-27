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


	IDEAL
IDEAL_MODE	EQU	1
	VERSION T300		; Code written for V3.0 TASM version.
	IDEAL
	P386N			; target machine.
	SMART			; Enable optimizations.
	WARN			; Full warnings.
	LOCALS ??
	MODEL	LARGE @filename
;	INCLUDE	"d:\library\wwlib.i"

CODE_2BIT	EQU	0
CODE_4BIT	EQU	1
CODE_RAW	EQU	2
CODE_SILENCE	EQU	3
MAGICNUMBER	EQU	00000DEAFh
MAGICNUMBER2	EQU	0BABEBABEh

;	VERSION T300		; Code written for V3.0 TASM version.
;	P386N			; target machine.
;	MODEL	LARGE @filename
;	WARN			; Full warnings.
;	LOCALS ??

	CODESEG

_2bitdecode	DB	-2, -1, 0, 1
;_2bitdecode	DB	-2, -1, 1, 2
_4bitdecode	DB	-9,-8,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,8
;_4bitdecode	DB	-16,-13,-10,-8,-6,-4,-2,-1,1,2,4,6,8,10,13,16

	GLOBAL	C Decompress_Frame:FAR
	PROC	C Decompress_Frame FAR USES bx cx edx ds si es di bp
	ARG	source:DWORD
	ARG	dest:DWORD
	ARG	count:WORD

	LOCAL	previous:BYTE
	LOCAL	incount:WORD

	; Initialize counter for number of bytes read from source.
	mov	[incount],0

	; Verify parameters for legality.
	cmp	[source],0
	je	??fini
	cmp	[dest],0
	je	??fini
	cmp	[count],0
	je	??fini

	; Fetch parameter values into working registers.
	lds	si,[source]		; Pointer to source data.
	les	di,[dest]		; Pointer to destination data.
	mov	cx,[count]		; Number of bytes to fill dest buffer.
	mov	dl,080h			; Previous sample (starting value).

??mainloop:
	; Check to see if the destination is full.  Exit if so.
	cmp	cx,0
	jle	??fini

	; Fetch code byte from input stream.
	xor	ah,ah
	mov	al,[ds:si]
	inc	[incount]
	inc	si
	shl	ax,2			; AH contains code.
	shr	al,2			; AL contains sub-code data.

	; Check to see if a raw sequence follows.
	cmp	ah,CODE_RAW
	jne	short ??try4bit

	; The code contains either a 5 bit delta or a count of raw samples
	; to dump out.
	test	al,00100000b
	je	short ??justraw

	; The lower 5 bits are actually a signed delta.  Sign extend the
	; delta and add it to the stream.
	shl	al,3
	sar	al,3
	add	dl,al
	mov	[es:di],dl
	dec	cx
	inc	di
	jmp	??mainloop

	; The lower 5 bits hold a count of the number of raw samples that
	; follow this code.  Dump these samples to the output buffer.
??justraw:
	mov	bx,cx
	xor	ah,ah
	inc	al
	mov	cx,ax
	shr	cx,1
	rep movsw
	adc	cx,cx
	rep movsb
	mov	cx,bx
	add	[incount],ax
	sub	cx,ax
	dec	di
	mov	dl,[es:di]		; Set "previous" value.
	inc	di
	jmp	??mainloop

	; Check to see if this is a 4 bit delta code sequence.
??try4bit:
	inc	al			; Following codes use AL+1
	cmp	ah,CODE_4BIT
	jne	short ??try2bit

	; A sequence of 4bit deltas follow.  AL equals the number of nibble
	; packed delta bytes to process.
??bit4loop:
	; Fetch nibble packed delta codes.
	mov	ah,[ds:si]
	mov	bl,ah
	inc	[incount]
	inc	si

	; Add first delta to 'previous' sample already in DL.
	and	bx,00001111b

	add	dl,[cs:_4bitdecode+bx]		; Add in delta
	pushf
	cmp	[cs:_4bitdecode+bx],0
	jl	short ??neg1
	popf
	jnc	short ??ok1
	mov	dl,0FFh
	jmp	short ??ok1
??neg1:
	popf
	jc	short ??ok1
	xor	dl,dl
??ok1:
	mov	dh,dl				; DH now holds new 'previous' sample.

	mov	bl,ah
	shr	bl,4
	add	dh,[cs:_4bitdecode+bx]		; Add in delta
	pushf
	cmp	[cs:_4bitdecode+bx],0
	jl	short ??neg2
	popf
	jnc	short ??ok2
	mov	dh,0FFh
	jmp	short ??ok2
??neg2:
	popf
	jc	short ??ok2
	xor	dh,dh
??ok2:

	; Output the two sample bytes.
	mov	[es:di],dx
	sub	cx,2
	add	di,2

	; Put the correct 'previous' sample in DL where it belongs.
	mov	dl,dh

	; If there are more deltas to process then loop back.
	dec	al
	jnz	short ??bit4loop

	jmp	??mainloop

	; Check to see if 2 bit deltas need to be processed.
??try2bit:
	cmp	ah,CODE_2BIT
	jne	??zerodelta

	; A sequence of 2bit deltas follow.  AL equals the number of 
	; packed delta bytes to process.
??bit2loop:
	; Fetch packed delta codes.
	mov	ah,[ds:si]
	inc	[incount]
	inc	si

	; Add first delta to 'previous' sample already in DL.
	mov	bl,ah
	and	bx,000011b
	add	dl,[cs:_2bitdecode+bx]		; Add in delta

	pushf
	cmp	[cs:_2bitdecode+bx],0
	jl	short ??neg3
	popf
	jnc	short ??ok3
	mov	dl,0FFh
	jmp	short ??ok3
??neg3:
	popf
	jc	short ??ok3
	xor	dl,dl
??ok3:

	mov	dh,dl
	ror	edx,8

	mov	bl,ah
	shr	bx,2
	and	bl,00000011b
	add	dl,[cs:_2bitdecode+bx]		; Add in delta
	
	pushf
	cmp	[cs:_2bitdecode+bx],0
	jl	short ??neg4
	popf
	jnc	short ??ok4
	mov	dl,0FFh
	jmp	short ??ok4
??neg4:
	popf
	jc	short ??ok4
	xor	dl,dl
??ok4:
	
	mov	dh,dl
	ror	edx,8

	mov	bl,ah
	shr	bx,4
	and	bl,00000011b
	add	dl,[cs:_2bitdecode+bx]		; Add in delta
     
	pushf
	cmp	[cs:_2bitdecode+bx],0
	jl	short ??neg5
	popf
	jnc	short ??ok5
	mov	dl,0FFh
	jmp	short ??ok5
??neg5:
	popf
	jc	short ??ok5
	xor	dl,dl
??ok5:
	
	mov	dh,dl
	ror	edx,8

	mov	bl,ah
	shr	bx,6
	and	bl,00000011b
	add	dl,[cs:_2bitdecode+bx]		; Add in delta
	
	pushf
	cmp	[cs:_2bitdecode+bx],0
	jl	short ??neg6
	popf
	jnc	short ??ok6
	mov	dl,0FFh
	jmp	short ??ok6
??neg6:
	popf
	jc	short ??ok6
	xor	dl,dl
??ok6:
	
	;mov	dh,dl
	ror	edx,8

	; Output the two sample bytes.
	mov	[es:di],edx
	sub	cx,4
	add	di,4

	; Put the correct 'previous' sample in DL where it belongs.
	rol	edx,8

	; If there are more deltas to process then loop back.
	dec	al
	jnz	??bit2loop

	jmp	??mainloop

	; There is a run of zero deltas.  Zero deltas merely duplicate
	; the 'previous' sample the requested number of times.
??zerodelta:
	xor	bh,bh
	mov	bl,al
	mov	al,dl
	sub	cx,bx
	xchg	cx,bx
	rep stosb
	mov	cx,bx
	jmp	??mainloop

	; Final cleanup and exit.
??fini:
	mov	ax,[incount]
	ret

	ENDP	Decompress_Frame

	END

