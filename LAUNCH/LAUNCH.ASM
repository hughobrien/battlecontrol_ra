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

;***********************************************************************************************
;***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
;***********************************************************************************************
;*                                                                                             *
;*                 Project Name : Command & Conquer -- launcher program                        *
;*                                                                                             *
;*                    File Name : launch.asm                                                   *
;*                                                                                             *
;*                   Programmer : Steve Tall                                                   *
;*                                                                                             *
;*                   Start Date : August 19, 1995                                              *
;*                                                                                             *
;*                  Last Update : Modified for RA, October 14th, 1996 [ST]                     *
;*                                                                                             *
;*                        Build : Compile and link with MASM 6                                 *
;*                                Note that masm will complain there is no stack because       *
;*                                we are not using a simplified segment model                  *
;*                                                                                             *
;*---------------------------------------------------------------------------------------------*
;* Functions:                                                                                  *
;*  Start -- Program entry point                                                               *
;*  Mem_Error -- report an out of memory error (not a function)                                *
;*  Disc_Error -- report an out of disk space error (not a function)                           *
;*  Delete_Swaps -- Deletes old swap files from the game directory                             *
;*  Setup_Environment -- Adds environment strings required for DOS4G professional              *
;*                                                                                             *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *




		TITLE	"Red Alert launcher"

		.386


;----------------------------------------------------------------------------------------------
; Defines for DOS system functions.
;
DOS_LOAD_AND_EXEC	=4B00H
DOS_ALLOC		=48H
DOS_FREE		=49h
DOS_GET_FREE_DISC_SPACE	=36H
DOS_SET_DIRECTORY	=3BH
DOS			=21H
DOS_SET_DTA		=1AH
DOS_FIND_FIRST		=4EH
DOS_FIND_NEXT		=4FH
DOS_DELETE_FILE		=41H
DOS_SET_ATTRIBUTES	=43H
DOS_SET_DRIVE		=0EH
DOS_RESIZE_ALLOCATION	=4Ah
DOS_EXIT		=4ch
DOS_PRINT_STRING	=9


;----------------------------------------------------------------------------------------------
; Defines for keyboard BIOS functions
;
KEYBOARD_BIOS		=16h
BIOS_CHECK_KEYBOARD	=11h
BIOS_GET_KEYSTROKE	=10h


;----------------------------------------------------------------------------------------------
; Defines for video bios functions
;
VIDEO_BIOS		=10h
BIOS_SET_VIDEO_MODE_3	=0003h


;----------------------------------------------------------------------------------------------
; Misc defines
;
MEM_REQUIRED		=1024 * 400	;Check for 400k low memory
INIT_FREE_DISK_SPACE	=15*1024*1024	;C&C requirement for disc space

MY_ALLOCATION		=1536/16	;only allow myself 1.5k to run in incl. psp and stack
					;you can find out how much space the program needs
					;by running WDISASM LAUNCH.OBJ
					;dont forget to add 256 bytes on for the psp


		include <pcmacro.16>


;----------------------------------------------------------------------------------------------
; Simplified segment models are for wimmin
;
; We want 32 bit instructions in a 16 bit segment
;

_code segment para public use16 'code'

		assume	ds:_data
		assume	es:_data
		assume	ss:_data
		assume	cs:_code



;*************************************************************************************************
;* Start -- Program entry point                                                                  *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      DOS return code from spawning the game                                           *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   08/19/95 ST: Created.                                                                       *
;*===============================================================================================*

Start:		;
		; Set up the segments and the stack pointer
		;
		cli
		mov	ax,_data
		mov	ds,ax
		mov	[Psp],es
		mov	ss,ax
		mov	sp,offset MyStack
		sti

		;
		; Modify the starting memory allocation to free enough for the game proper
		;
		save	ax
		mov	bx,MY_ALLOCATION
		mov	ah,DOS_RESIZE_ALLOCATION
		int	DOS
		restore	ax
		bcs	Mem_Error

		;
		; See if we have enough free memory to launch
		;
		mov	ah,DOS_ALLOC
		mov	bx,-1		;I want it all! hahaha
		int	DOS
		jnc	Mem_Error	;shouldnt ever succeed but...
		cmp	ax,8
		jnz	Mem_Error
		cmp	bx,(MEM_REQUIRED/16)-MY_ALLOCATION
		bls	Mem_Error	;oh dear

		;
		; See if there is enough free disc space to launch
		;
		xor	dl,dl
		mov	ah,DOS_GET_FREE_DISC_SPACE
		int	DOS

		; dos get free disc space returns with the following
		; ax - sectors per cluster
		; bx - number of available clusters
		; cx - bytes per sector
		; dx - cluster on the drive

		mul	bx	;clusters avail*sectors per cluster
		shl	edx,16
		mov	dx,ax
		mov	eax,edx
		and	ecx,65535
		mul	ecx	;*bytes per sector
		cmp	eax,INIT_FREE_DISK_SPACE
		blo	Disc_Error

		;
		; Get the directory we were run from and cd to it
		;
		mov	es,[Psp]
		mov	bx,2ch
		mov	es,es:[bx]	;es points to env
		xor	di,di
		xor	al,al
		mov	cx,-1

		;
		; Search for 0,0 as that aways terminates the environment block
		;
@@again:	repnz	scasb
		cmp_b	es:[di],al
		jnz	@@again
		lea	si,[di+3]	;skip length word and second zero

		;
		; Copy the directory name to temporary workspace
		;
		mov	di,si
		mov	cx,-1
		repnz	scasb
		neg	cx
		mov	bx,cx
		mov	cx,-1
		std
		mov	al,'\'
		repnz	scasb
		neg	cx
		sub	bx,cx
		mov	cx,bx
		inc	cx
		cld

		mov	di,offset Dta
		push	ds
		mov	ax,es
		mov	bx,ds
		mov	es,bx
		mov	ds,ax
		rep	movsb
		xor	al,al
		stosb
		pop	ds

		;
		; Actually set the drive and path
		;
		mov	dl,[Dta]
		sub	dl,'A'
		mov	ah,DOS_SET_DRIVE
		int	DOS

		mov	dx,offset Dta
		mov	ah,DOS_SET_DIRECTORY
		int	DOS

		;
		; Delete all the old swap files
		;
		mov	dx,offset Dta
		mov	ah,DOS_SET_DTA
		int	DOS
		call	Delete_Swaps

		;
		; Add in the environment strings required for DOS4G professional
		;
		call	Setup_Environment

		;
		; Set up the parameters to launch c&c
		;
		mov	es,[Psp]
		mov	dx,offset GameName
		mov	bx,offset GameParameterBlock

		mov	ax,[EnvironmentSegment]		;Initialised by Setup_Environment
		mov_w	[bx],ax		;ptr to environment

		;
		; just pass the command tail we got straight through
		;
		mov	ax,80h
		mov	[bx+2],ax	;offset of command tail
		mov	ax,[Psp]
		mov	[bx+4],ax	;segment of command tail

		mov	es,ax
		mov	ax,es:[2ch]
		mov	[bx+8],ax	;segment of first fcb
		mov	[bx+12],ax	;segment of second fcb

		mov	ax,_data
		mov	es,ax

		;
		; Run the main game program
		;
		mov	ax,DOS_LOAD_AND_EXEC	;load and execute program
		int	DOS


		;
		; Restore teh environment memory
		;
		mov	ax,[EnvironmentSegment]
		test	ax,ax
		jz	@@no_free
		mov	es,ax
		mov	ah,DOS_FREE
		int	DOS


@@no_free:	;
		; Quit to DOS
		;
		mov	ah,DOS_EXIT
		int	DOS




;*************************************************************************************************
;* Mem_Error -- Print a memory error message and quit                                            *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      undefined                                                                        *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   08/19/95 ST: Created.                                                                       *
;*===============================================================================================*
Mem_Error:	mov	ax,BIOS_SET_VIDEO_MODE_3
		int	VIDEO_BIOS
		mov	dx,offset MemErrorTxt
		mov	ah,DOS_PRINT_STRING
		int	DOS

		mov	dx,offset MoreInfoTxt
Error_In:	mov	ah,DOS_PRINT_STRING
		int	DOS

		;
		; wait for keypress
		;

nochar:		mov	ah,BIOS_CHECK_KEYBOARD
		int	KEYBOARD_BIOS
		beq	nochar

		;
		; get the ket out of the buffer
		;
		mov	ah,BIOS_GET_KEYSTROKE
		int	KEYBOARD_BIOS

		;
		; Quit to DOS
		;
		mov	ah,DOS_EXIT
		int	DOS






;*************************************************************************************************
;* Disc_Error -- Prints a disk error message and exits                                           *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      DOS return code from spawning the game                                           *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   08/19/95 ST: Created.                                                                       *
;*===============================================================================================*
Disc_Error:	mov	ax,BIOS_SET_VIDEO_MODE_3
		int	VIDEO_BIOS
		mov	dx,offset DiscErrorTxt
		jmp	Error_In







;*************************************************************************************************
;* Setup_Environment -- Create a new environment block with the set DOS4GVM= stuff               *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* Note: Modifies the global variable 'EnvironmentStrings' to point to the start of our new      *
;*       environment block. This memory will need to be freed later.                             *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   10/14/96 ST: Created.                                                                       *
;*===============================================================================================*
Setup_Environment proc near

		;
		; Point to default environment.
		;
		mov	[EnvironmentSegment],0

		;
		; Get the address of our environment block into es
		;
		mov	es,[Psp]
		mov	bx,2ch
		mov	es,es:[bx]	;es points to env

		;
		; Search for the end of the block to get its length
		;
		xor	di,di
		xor	al,al
		mov	cx,-1

@@search:	repnz	scasb
		cmp_b	es:[di],al
		jnz	@@search

		;
		; di is length of environment block
		;
		lea	bx,[di+256]	; a little extra to be sure.

		;
		; Allocate memory for a copy of the environment.
		;
		push	di
		mov	ah,DOS_ALLOC
		shr	bx,4		;needs to be number of paragraphs
		int	DOS
		jnc	@@ok

		;
		; Oops. Not enough memory. We are screwed so just exit.
		;
		pop	di
		jmp	@@out

@@ok:           ;
		; Save the pointer to our new environment
		; We can also use this to free the memory later
		;
		mov	[EnvironmentSegment],ax

		;
		; Copy the original environment to the newly alloced memory
		;
		mov	es,ax
		pop	cx		; size to copy

		push	ds
		mov	ds,[Psp]
		mov	bx,2ch
		mov	ds,ds:[bx]	;ds points to original environment

		xor	si,si
		xor	di,di
		rep	movsb
		pop	ds

		mov	si,offset Dos4gEnvironment

@@copy_loop:	lodsb
		stosb
		test	al,al
		jnz	@@copy_loop

		;
		; Copy the final zero. The environment must be terminated by 2 zeros.
		;
		movsb

@@out:		ret

Setup_Environment endp





;*************************************************************************************************
;* Delete_Swaps -- Delete any swap files left over from a previous game                          *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   08/19/95 ST: Created.                                                                       *
;*===============================================================================================*
Delete_Swaps proc near

		;
		; Use 'Find first/next' to find the swap files
		;
		mov	dx,offset SwapName
		mov	cx,7	;attributes
		mov	ah,DOS_FIND_FIRST
		int	DOS
		bcs	@@out		;no matching files

		;
		; Make sure it isn't read only
		;
@@loop:		mov	dx,offset Dta+1eh
		mov	ah,DOS_SET_ATTRIBUTES
		mov	al,1
		xor	cx,cx		;attributes
		int	DOS

		;
		; Delete the file
		;
		mov	dx,offset Dta+1eh
		mov	ah,DOS_DELETE_FILE
		int	DOS

		;
		; Find the next one
		;
		mov	ah,DOS_FIND_NEXT
		int	DOS
		bcc	@@loop

@@out:		ret

Delete_Swaps endp





_code ends	;end of code segment









;----------------------------------------------------------------------------------------------
;
; Complex data segment
;
;

_data segment dword public use16 'data'


EnvironmentSegment	dw	0		;ptr to environment to pass to child process
Psp			dw	0		;segment addr of program segment prefix
GameParameterBlock	db	16h dup (0)	;required parameters for DOS launch

GameName	db	"GAME.DAT",0	;this is the name of the app to be spawned
SwapName	db	"*.SWP",0	;swap files always have a .SWP extension

;
; Environment to be set for DOS4G professional
;
Dos4gEnvironment db	"DOS4GVM=SwapMin:12M,SwapInc:0",0,0

;
; Error and warning messages
;
MemErrorTxt	db	"Warning - There is very little free conventional DOS memory in the system.",13,10,"$"

DiscErrorTxt	db	"Error - insufficient disk space to run Red Alert."
		db	13,10,"Red Alert requires 15,728,640 bytes of free disk space.",13,10	;this string will
											;run into the next because
											;there is no '$'
MoreInfoTxt	db	"Please read the Red Alert manual for more information.",13,10,13,10
		db	"Press a key to continue.",13,10,"$"


Dta		db	128 dup (0)	;enough for complete path


;*************************************************************
;
; The stack
;

StackSpace	db	256 dup (0)	;256 byte stack!
MyStack 	label 	byte		;The stack starts here and grows down.

EndCode		label	byte		;The end of the data segment


_data ends

end Start
