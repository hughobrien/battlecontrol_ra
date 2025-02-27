#
#	Command & Conquer Red Alert(tm)
#	Copyright 2025 Electronic Arts Inc.
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#* $Header$
#***********************************************************************************************
#***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
#***********************************************************************************************
#*                                                                                             *
#*                 Project Name : Command & Conquer                                            *
#*                                                                                             *
#*                    File Name : MAKEFILE                                                     *
#*                                                                                             *
#*                   Programmer : Joe L. Bostic                                                *
#*                                                                                             *
#*                   Start Date : 03/02/95                                                     *
#*                                                                                             *
#*                  Last Update : March 2, 1995 [JLB]                                          *
#*                                                                                             *
#*---------------------------------------------------------------------------------------------*
#* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

.SILENT
.OPTIMIZE
.ERASE

#---------------------------------------------------------------------------
# Working values depending on what target executable will be created.
#---------------------------------------------------------------------------

!ifdef GERMAN
LANGUAGE=GERMAN
!else
!ifdef FRENCH
LANGUAGE=FRENCH
!else
LANGUAGE=ENGLISH
!endif
!endif

!ifdef WIN32
WWFLAT=..\win32lib
WWOBJ=obj\win32\$(LANGUAGE)
LINKFILE=win95.lnk
CC=..\watcom\binnt\wpp386
LIB=..\watcom\binnt\wlib
!else
WWFLAT=..\wwflat32
WWOBJ=obj\dos
LINKFILE=conquer.lnk
CC=..\watcom\binnt\wpp386
LIB=..\watcom\binnt\wlib
!endif

#---------------------------------------------------------------------------
# Path macros: one path for each file type.
#  These paths are used to tell make where to find/put each file type.
#---------------------------------------------------------------------------
.asm:  .
.c:    .
.cpp:  .
.h:    .
.obj:  $(WWOBJ)
.lib:  $(WWFLAT)\lib
.exe:  ..\run


#===========================================================================
# Compiler and assembler flags.
#===========================================================================
!ifdef WIN32
CC_CFG = /d0                            # No debugging information	( else use /d1 )
CC_CFG += /DWIN32=1
CC_CFG += /D_WIN32
CC_CFG += /DWOLAPI_INTEGRATION
CC_CFG += /DWINSOCK_IPX
CC_CFG += /D$(LANGUAGE)=1
CC_CFG += /i=..\dxsdk\inc
CC_CFG += /i=..\watcom\h\nt                # NT include directory.
CC_CFG += /i=..\watcom\H                   # Normal Watcom include directory.
CC_CFG += /i=$(WWFLAT)\INCLUDE          # Normal library include directory.
CC_CFG += /i=..\winvq\include           # Includes player (VQ) directory.
CC_CFG += /bt=NT
CC_CFG += /otxan
CC_CFG += /5r                           # Pentium optimized register calling conventions.
!else
CC_CFG = /d1                            # Partial debug (line numbers only)
CC_CFG += /i=..\watcom\H                   # Normal Watcom include directory.
CC_CFG += /i=$(WWFLAT)\INCLUDE          # Normal library include directory.
CC_CFG += /i=..\vq\include              # Includes player (VQ) directory.
CC_CFG += /DDOS4G                       # Must be defined for Greenleaf
CC_CFG += /5s                           # Pentium optimized stack calling conventions.
CC_CFG += /DGF_WATCOM_S                 # Must be defined for Greenleaf with /3s
CC_CFG += /bt=DOS
!endif

CC_CFG += /i=..\gcl510\H                # Includes Greenleaf headers.
CC_CFG += /of+                          # Generate traceable stack frames.
CC_CFG += /zp1                          # Pack structures on byte boundary.
CC_CFG += /s                            # Remove stack check calls.
CC_CFG += /j                            # char is now signed.
CC_CFG += /fh=$(WWOBJ)\conquer.pch      # Use precompiled headers.
CC_CFG += /fhq
CC_CFG += /we                           # Treat all warnings as errors.
CC_CFG += /w8                           # Most warnings enabled.
CC_CFG += /ri                           # char and shorts are returned as int.
CC_CFG += /zq                           # Operate quietly.

ASM_CFG = /i$(WWFLAT)\INCLUDE           # Include directory.
ASM_CFG += /zd                          # Debugging information line numbers.
ASM_CFG += /t                           # Quiet operation.
ASM_CFG += /m                           # Allow multiple passes.
ASM_CFG += /w+                          # Enable maximum warnings.
ASM_CFG += /jJUMPS                      # Enable jump optimizations.
ASM_CFG += /ml                          # Case sensitivity on code.


#---------------------------------------------------------------------------
# Implicit rules
# Compiler:
# 	($< = full dependent with path)
# Assembler:
# 	output obj's are constructed from .obj: & the $& macro
# 	($< = full dependent with path)
# 	tasm's cfg file is not invoked as a response file.
#---------------------------------------------------------------------------

.c.obj: .AUTODEPEND
	echo Compiling $<
	*$(CC) $(CC_CFG) -fo$(WWOBJ)\$^. $<

.cpp.obj: .AUTODEPEND
	echo Compiling $<
	*$(CC) $(CC_CFG) -fo$(WWOBJ)\$^. $<

.asm.obj:
	echo Assembling $<
	utils\tasm $(ASM_CFG) $<, $(WWOBJ)\$^.

#---------------------------------------------------------------------------
# Object modules.
#---------------------------------------------------------------------------
OBJECTS = &
	AADATA.OBJ &
	ABSTRACT.OBJ &
	ADATA.OBJ &
	AIRCRAFT.OBJ &
	ANIM.OBJ &
	AUDIO.OBJ &
	BAR.OBJ &
	BASE.OBJ &
	BBDATA.OBJ &
	BDATA.OBJ &
	BUILDING.OBJ &
	BULLET.OBJ &
	CARGO.OBJ &
	CARRY.OBJ &
	CCFILE.OBJ &
	CCINI.OBJ &
	CCPTR.OBJ &
	CDATA.OBJ &
	CELL.OBJ &
	CHECKBOX.OBJ &
	CHEKLIST.OBJ &
	COLRLIST.OBJ &
	COMBAT.OBJ &
	COMBUF.OBJ &
	CONNECT.OBJ &
	CONQUER.OBJ &
	CONST.OBJ &
	CONTROL.OBJ &
	COORD.OBJ &
	CRATE.OBJ &
	CREDITS.OBJ &
	CREW.OBJ &
	DEBUG.OBJ &
	DIAL8.OBJ &
	DIALOG.OBJ &
	DISPLAY.OBJ &
	DOOR.OBJ &
	DRIVE.OBJ &
	DROP.OBJ &
	DYNAVEC.OBJ &
	EDIT.OBJ &
	EGOS.OBJ &
	ENDING.OBJ &
	EVENT.OBJ &
	EXPAND.OBJ &
	FACE.OBJ &
	FACING.OBJ &
	FACTORY.OBJ &
	FINDPATH.OBJ &
	FLASHER.OBJ &
	FLY.OBJ &
	FOOT.OBJ &
	FUSE.OBJ &
	GADGET.OBJ &
	GAMEDLG.OBJ &
	GAUGE.OBJ &
	GLOBALS.OBJ &
	GOPTIONS.OBJ &
	GSCREEN.OBJ &
	HDATA.OBJ &
	HEAP.OBJ &
	HELP.OBJ &
	HOUSE.OBJ &
	IDATA.OBJ &
	INFANTRY.OBJ &
	INI.OBJ &
	INIT.OBJ &
	INTRO.OBJ &
	IOMAP.OBJ &
	IOOBJ.OBJ &
	IPX.OBJ &
	IPXADDR.OBJ &
	IPXCONN.OBJ &
	IPXGCONN.OBJ &
	IPXMGR.OBJ &
	IPXPROT.OBJ &
	JSHELL.OBJ &
	LAYER.OBJ &
	LINK.OBJ &
	LIST.OBJ &
	LOADDLG.OBJ &
	LOGIC.OBJ &
	MAP.OBJ &
	MAPEDDLG.OBJ &
	MAPEDIT.OBJ &
	MAPEDPLC.OBJ &
	MAPEDTM.OBJ &
	MAPSEL.OBJ &
	MENUS.OBJ &
	MISSION.OBJ &
	MOUSE.OBJ &
	MPLAYER.OBJ &
	MSGBOX.OBJ &
	MSGLIST.OBJ &
	NETDLG.OBJ &
	NULLCONN.OBJ &
	NULLDLG.OBJ &
	NULLMGR.OBJ &
	OBJECT.OBJ &
	ODATA.OBJ &
	OPTIONS.OBJ &
	OVERLAY.OBJ &
	POWER.OBJ &
	PROFILE.OBJ &
	QUEUE.OBJ &
	RADAR.OBJ &
	RADIO.OBJ &
	REINF.OBJ &
	RULES.OBJ &
	SAVELOAD.OBJ &
	SCENARIO.OBJ &
	SCORE.OBJ &
	SCROLL.OBJ &
	SDATA.OBJ &
	SESSION.OBJ &
	SHAPEBTN.OBJ &
	SIDEBAR.OBJ &
	SLIDER.OBJ &
	SMUDGE.OBJ &
	SOUNDDLG.OBJ &
	SPECIAL.OBJ &
	STARTUP.OBJ &
	STATBTN.OBJ &
	SUPER.OBJ &
	TAB.OBJ &
	TACTION.OBJ &
	TARGET.OBJ &
	TDATA.OBJ &
	TEAM.OBJ &
	TEAMTYPE.OBJ &
	TECHNO.OBJ &
	TEMPLATE.OBJ &
	TERRAIN.OBJ &
	TEVENT.OBJ &
	TEXTBTN.OBJ &
	THEME.OBJ &
	TOGGLE.OBJ &
	TRACKER.OBJ &
	TRIGGER.OBJ &
	TRIGTYPE.OBJ &
	TXTLABEL.OBJ &
	UDATA.OBJ &
	UNIT.OBJ &
	UTRACKER.OBJ &
	VDATA.OBJ &
	VECTOR.OBJ &
	VERSION.OBJ &
	VESSEL.OBJ &
	VISUDLG.OBJ &
	VORTEX.OBJ &
	WARHEAD.OBJ &
	WEAPON.OBJ &
	MCIMOVIE.OBJ &
	MCI.OBJ &
	MPGSET.OBJ &
	ICONLIST.OBJ &
	WOL_MAIN.OBJ &
	WOL_CHAT.OBJ &
	RAWOLAPI.OBJ &
	WOLAPIOB.OBJ &
	W95TRACE.OBJ &
	COMINIT.OBJ &
	WOL_LOGN.OBJ &
	WOLEDIT.OBJ &
	PASSEDIT.OBJ &
	SEDITDLG.OBJ &
	DIBFILE.OBJ &
	DIBUTIL.OBJ &
	WOL_GSUP.OBJ &
	UDPADDR.OBJ &
	WSPROTO.OBJ &
	WSPUDP.OBJ &
	WSPIPX.OBJ &
	_WSPROTO.OBJ &
	TOOLTIP.OBJ &
	WOL_OPT.OBJ &
	WOL_CGAM.OBJ &
	BIGCHECK.OBJ &
	WOL_DNLD.OBJ &
	WOLSTRNG.OBJ


# Files that are candidates for library submission,
# since they depend on the westwood library to a great
# degree
LIBFILES = &
	ROTBMP.OBJ &
	SPRITE.OBJ &

# Self contained technology modules
TECHFILES = &
	LZO1X_C.OBJ &
	LZO1X_D.OBJ &
	LZOPIPE.OBJ &
	LZOSTRAW.OBJ &
	LZW.OBJ &
	LZWPIPE.OBJ &
	LZWSTRAW.OBJ &
	BUFF.OBJ &
	BENCH.OBJ &
	RECT.OBJ &
	MPU.OBJ &
	READLINE.OBJ &
	PKPIPE.OBJ &
	PKSTRAW.OBJ &
	XSTRAW.OBJ &
	XPIPE.OBJ &
	RNDSTRAW.OBJ &
	PK.OBJ &
	BLWSTRAW.OBJ &
	STRAW.OBJ &
	B64STRAW.OBJ &
	LCWSTRAW.OBJ &
	CRCSTRAW.OBJ &
	SHASTRAW.OBJ &
	RAMFILE.OBJ &
	INI.OBJ &
	LCWPIPE.OBJ &
	LCWCOMP.OBJ &
	LCW.OBJ &
	CRCPIPE.OBJ &
	SHAPIPE.OBJ &
	PIPE.OBJ &
	BLOWPIPE.OBJ &
	B64PIPE.OBJ &
	BASE64.OBJ &
	FIXED.OBJ &
	MIXFILE.OBJ &
	CDFILE.OBJ &
	BFIOFILE.OBJ &
	RAWFILE.OBJ &
	MP.OBJ &
	INT.OBJ &
	MONOC.OBJ &
	RANDOM.OBJ &
	RGB.OBJ &
	HSV.OBJ &
	PALETTE.OBJ &
	BLOWFISH.OBJ &
	SHA.OBJ &
	CRC.OBJ &
	SENDFILE.OBJ

!ifdef WIN32
OBJECTS += 2KEYFBUF.OBJ &
	CPUID.OBJ &
	GETCPU.OBJ &
	INTERPAL.OBJ &
	WINASM.OBJ &
	WINSTUB.OBJ &
	2TXTPRNT.OBJ &
	WRITEPCX.OBJ &
	IPX95.OBJ &
	2KEYFRAM.OBJ &
	TCPIP.OBJ &
	INTERNET.OBJ &
	DDE.OBJ &
	CCDDE.OBJ &
	STATS.OBJ &
	PACKET.OBJ &
	KEY.OBJ &
	FIELD.OBJ

!else
OBJECTS += KEYFBUFF.OBJ &
	TXTPRNT.OBJ &
	KEYFRAME.OBJ
!endif

!ifdef WIN32
PROJ_LIBS = &
	win32lib.lib

!else
PROJ_LIBS = &
	wwflat32.lib
!endif

VQ_LIBS = &
	vqa32wp.lib &
	vqm32wp.lib

GCL_LIBS = &
	gclfr3s.lib

MEMCHECK_LIBS = &
	MCA3S.LIB

############################################################################
# Pre-compilation process. Move old files to backup directory.
.BEFORE
	-if exist *.bak move *.bak bak
	-if exist $(WWOBJ)\*.pch del $(WWOBJ)\*.pch

# After make has completed.
.AFTER

# If there is an abnormal termination in make process (e.g., error in compile).
.ERROR


#############################################################################
# Default target
!ifdef WIN32
all: ra95.exe
!else
all: game.dat
!endif


#############################################################################
# Builds the JSHELL.LIB file.
$(WWOBJ)\jshell.lib: $(LIBFILES) $(WWOBJ)\jshell.lnk
	$(LIB) -c $^@ @$(WWOBJ)\jshell.lnk

$(WWOBJ)\jshell.lnk: makefile
	%create $^@
	for %index in ($(LIBFILES))  do %append $^@ -+ $(WWOBJ)\%index

#############################################################################
# Builds the TECH.LIB file.
$(WWOBJ)\tech.lib: $(TECHFILES) $(WWOBJ)\tech.lnk
	$(LIB) -c $^@ @$(WWOBJ)\tech.lnk

$(WWOBJ)\tech.lnk: makefile
	%create $^@
	for %index in ($(TECHFILES))  do %append $^@ -+ $(WWOBJ)\%index

#############################################################################
# Builds the stub replacement program.
CWSTUB.OBJ: CWSTUB.C
	*wcc /i=..\watcom\h /dQUIET /dVMM /ms /zQ -fo$(WWOBJ)\$^. $<

CWSTUB.EXE: CWSTUB.OBJ
	*watcom\binw\wlink system dos file $(WWOBJ)\cwstub.obj name cwstub.exe option quiet library \wat\lib386\dos\clibs.lib, \wat\lib386\math87s.lib, \wat\lib386\dos\emu87.lib


#############################################################################
# Build the EXE
game.dat: $(WWOBJ)\tech.lib $(WWOBJ)\jshell.lib $(OBJECTS) $(LINKFILE) $(TECHFILE)
	-Echo "dos.exe" linking phase.
        ..\watcom\binw\wlink name ..\run\dos.exe @$(LINKFILE)
	-Echo Binding phase.
        -..\watcom\binw\wstrip -n -q ..\run\dos.exe ..\run\temp.tmp
	-..\watcom\4gwbind ..\watcom\4gwpro.exe ..\run\temp.tmp ..\run\game.dat -vmon
# -copy ..\run\game.dat C:\westwood\redalert
# -copy ..\run\game.dat C:\westwood\ra
# -copy ..\run\dos.exe C:\westwood\redalert
#	-copy ..\run\game.dat ..\cd\install
	-Echo "game.dat" executable completed.

ra95.exe: $(WWOBJ)\tech.lib $(WWOBJ)\jshell.lib $(OBJECTS) $(LINKFILE) mpgdll.lib
	Echo "ra95.exe" linking phase. [$(LANGUAGE)]
#         nwlink name ..\run\$@ @$(LINKFILE)
# ajw - Steve Tall replaced wlink with nwlink. Watcom fix allows more debug symbols in exe, so allows debugging in WD.
#        ..\watcom\binw\wlink name ..\run\$@ @$(LINKFILE)
        linker\nwlink name ..\run\$@ @$(LINKFILE)
#        ..\watcom\binnt\WRC cc_icon ..\run\$@
#        copy ..\run\ra95.exe C:\westwood\redalert
#        copy ..\run\ra95.exe C:\westwood\ra
	Echo "ra95.exe" executable completed. [$(LANGUAGE)]


#############################################################################
# This creates the linker command file for the DOS version.
conquer.lnk : makefile
	%create $^@
	%append $^@ system dos4g
	%append $^@ option stack=128k
	%append $^@ option redefsok
	%append $^@ option quiet
	%append $^@ option map
	%append $^@ option eliminate
	%append $^@ option caseexact
	%append $^@ debug all
	%append $^@ library $(WWOBJ)\jshell.lib
	%append $^@ library $(WWOBJ)\tech.lib
	for %index in ($(OBJECTS))  do %append $^@ file $(WWOBJ)\%index
	for %index in ($(PROJ_LIBS)) do %append $^@ library $(WWFLAT)\lib\%index
	for %index in ($(VQ_LIBS)) do %append $^@ library ..\vq\lib\%index
	for %index in ($(GCL_LIBS)) do %append $^@ library ..\gcl510\w10\%index
#	%append $^@ debug watcom all


#############################################################################
# This creates the linker command file for the Windows 95 version.
win95.lnk : makefile
	%create $^@
	%append $^@ system win95
	%append $^@ option redefsok
	%append $^@ option quiet
	%append $^@ option map
        %append $^@ option eliminate
	%append $^@ option caseexact
	%append $^@ option stack=128k
#	%append $^@ debug watcom all
#	%append $^@ debug all
	for %index in ($(OBJECTS))  do %append $^@ file $(WWOBJ)\%index
	%append $^@ library $(WWOBJ)\jshell.lib
	%append $^@ library $(WWOBJ)\tech.lib
	%append $^@ library $(WWFLAT)\lib\win32lib.lib
	%append $^@ library ..\winvq\lib\vqa32wp.lib
	%append $^@ library ..\winvq\lib\vqm32wp.lib
     	%append $^@ library ipx\wwipx32.lib
	%append $^@ library ..\dxsdk\lib\dxguid.lib
	%append $^@ library ..\dxsdk\lib\ddraw.lib
	%append $^@ library ..\dxsdk\lib\dsound.lib
	%append $^@ library $(WWFLAT)\lib\keyboard.lib
	%append $^@ library mpgdll.lib
	%append $^@ library ..\dxmedia\lib\amstrmid.lib
	%append $^@ library ..\dxmedia\lib\strmbasd.lib
#	%append $^@ library ..\watcom\lib386\nt\uuid.lib
	%append $^@ library uuid.lib

#############################################################
# Update source and art to network.
update: pre .SYMBOLIC
	-copy i:\cd1\*.* f:\projects\c&c0\cd\win95\cd1 /s /u
	-copy i:\cd2\*.* f:\projects\c&c0\cd\win95\cd2 /s /u
#	-copy i:\cd1\*.* f:\projects\c&c0\cd\dos\cd1 /s /u
#	-copy i:\cd2\*.* f:\projects\c&c0\cd\dos\cd2 /s /u
	-copy ..\art\ingame\*.* f:\projects\c&c0\art\ingame /u /v /s
	-copy ..\audio\sfx\*.* f:\projects\c&c0\audio\ingame\sfx /u /v /s
	-copy *.* f:\projects\c&c0\code /v /s /u
	-copy ..\wwflat32\*.* f:\projects\c&c0\wwflat32 /v /s /u
	-copy ..\win32lib\*.* f:\projects\c&c0\win32lib /v /s /u
	-copy ..\vq\*.* f:\projects\c&c0\vq /v /s /u
	-copy ..\winvq\*.* f:\projects\c&c0\winvq /v /s /u

pre: .SYMBOLIC
	-copy f:\projects\c&c0\editor\english\*.exe i:\cd1\install /u
	-copy f:\projects\c&c0\editor\english\*.exe i:\cd2\install /u
	-copy f:\projects\c&c0\editor\english\edit.dat i:\cd1\install /u
	-copy f:\projects\c&c0\editor\english\edit.dat i:\cd2\install /u
	-copy ..\run\rules.ini ..\maps /u
	-copy ..\run\rules.ini f:\projects\c&c0\maps /u
	-watcom\binw\wstrip -n -q ..\run\ra95.exe ..\run\ra95.exe
	-copy ..\run\ra95.exe i:\cd1\install /u
	-copy ..\run\ra95.exe i:\cd2\install /u
	-copy ..\run\game.dat i:\cd1\install /u
	-copy ..\run\game.dat i:\cd2\install /u
	packlist SETUP.LST
	-copy setup.pkg i:\cd1\setup95 /u
 	-copy setup.pkg i:\cd2\setup95 /u
	-mkdir f:\projects\c&c0\playtest\%_DATE
	-copy ..\run\ra95.exe f:\projects\c&c0\playtest\%_DATE /u /v
	-copy ..\run\game.dat f:\projects\c&c0\playtest\%_DATE /u /v
	-copy *.map f:\projects\c&c0\playtest\%_DATE /u /v
	-copy *.cpp *.h f:\projects\c&c0\playtest\%_DATE /u /v


#############################################################################
# Explicit rules to build the master zip files (used by Codewrite merge).
BILL_R.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\bill_r.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\bill_r.zip *.* eng\conquer.txt

MARIA_L.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\maria_l.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\maria_l.zip *.* eng\conquer.txt

BARRY_G.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\barry_g.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\barry_g.zip *.* eng\conquer.txt

PHIL_G.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\phil_g.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\phil_g.zip *.* eng\conquer.txt

DAVID_D.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\david_d.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\david_d.zip *.* eng\conquer.txt

BILL_P.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\bill_p.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\bill_p.zip *.* eng\conquer.txt

STEVE_T.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\steve_t.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\steve_t.zip *.* eng\conquer.txt

VICTOR_G.ZIP: pkzip.dat .SYMBOLIC
	-del f:\projects\c&c0\victor_g.zip
	-pkzip -p -u -x@pkzip.dat f:\projects\c&c0\victor_g.zip *.* eng\conquer.txt

# Special "mega-zip" process.
JOE_B.ZIP: pkzip.dat .SYMBOLIC
	-pkzip -rp -u -xcps\*.* -x@pkzip.dat f:\projects\c&c0\joe_b.zip


#############################################################################
# Rebuilds the master zip control file. This is used by the zip process.
PKZIP.DAT: makefile .SYMBOLIC
	%create $^@
	%append $^@ *.000
	%append $^@ *.@@@
	%append $^@ *.bak
	%append $^@ *.bat
	%append $^@ *.cfg
	%append $^@ *.csm
	%append $^@ *.dat
	%append $^@ *.def
	%append $^@ *.doc
	%append $^@ *.dsw
	%append $^@ *.err
	%append $^@ *.ewp
	%append $^@ *.ext
	%append $^@ *.i
	%append $^@ *.ide
	%append $^@ *.lnk
	%append $^@ *.log
	%append $^@ *.lst
	%append $^@ *.mac
	%append $^@ *.map
	%append $^@ *.mbt
	%append $^@ *.mk
	%append $^@ *.mk1
	%append $^@ *.mrt
	%append $^@ *.obj
	%append $^@ *.obr
	%append $^@ *.out
	%append $^@ *.pch
	%append $^@ *.pfs
	%append $^@ *.pgp
	%append $^@ *.pif
	%append $^@ *.pjt
	%append $^@ *.prf
	%append $^@ *.pro
	%append $^@ *.ptg
	%append $^@ *.rc
	%append $^@ *.rep
	%append $^@ *.rpt
	%append $^@ *.rst
	%append $^@ *.sym
	%append $^@ *.tag
	%append $^@ *.td
	%append $^@ *.td
	%append $^@ *.tgt
	%append $^@ *.tmp
	%append $^@ *.tr
	%append $^@ *.tr
	%append $^@ *.txt
	%append $^@ *.vec
	%append $^@ *.wpj
	%append $^@ *.zip
	%append $^@ *.~*
	%append $^@ an_prefs
	%append $^@ state.rst


#--------------------------------------------------------------------------
# The IPX assembly object files are created in a special way:
# IPXREAL is the real-mode code that gets stuffed into memory by protected-
# mode code.  It's assembled, then converted into a big header file by
# the 'EBN' utility.
# IPXPROT is the protected-mode code that includes IPXREAL.IBN, and
# provides routines to let C++ read the code's address & size.
#--------------------------------------------------------------------------
$(WWOBJ)\ipxreal.ibn: $(WWOBJ)\ipxreal.obj
	%create $^*.rsp
	%append $^*.rsp $(WWOBJ)\$^&.obj
	%append $^*.rsp $(WWOBJ)\$^&.exe
	%append $^*.rsp $(WWOBJ)\$^&.map
	utils\tlink @$^*.rsp
	utils\tdstrip $(WWOBJ)\ipxreal.exe
	utils\ebn $(WWOBJ)\ipxreal.exe

$(WWOBJ)\ipxreal.obj:	ipxreal.asm
	utils\tasm /zn /la /ml /m2 ipxreal.asm, $(WWOBJ)\ipxreal.obj

ipxprot.obj: $(WWOBJ)\ipxreal.ibn ipxprot.asm
	utils\tasm $(ASM_CFG) ipxprot.asm, $(WWOBJ)\ipxprot.obj
#	copy $(WWOBJ)\ipxprot.obj d:obj /U


ipx.obj: ipx.cpp function.h
	echo Compiling $[.
	*$(CC) $(CC_CFG) -zz -fo$(WWOBJ)\$^. $[*.cpp

ipxmgr.obj: ipxmgr.cpp function.h
	echo Compiling $[.
	*$(CC) $(CC_CFG) -zz -fo$(WWOBJ)\$^. $[*.cpp

ipxconn.obj: ipxconn.cpp function.h
	echo Compiling $[.
	*$(CC) $(CC_CFG) -zz -fo$(WWOBJ)\$^. $[*.cpp

ipx95.obj: ipx95.cpp function.h
	echo Compiling $[.
	*$(CC) $(CC_CFG) -zz -fo$(WWOBJ)\$^. $[*.cpp

winstub.obj: winstub.cpp ipx95.h tcpip.h function.h
	echo Compiling $[.
	*$(CC) $(CC_CFG) -zz -fo$(WWOBJ)\$^. $[*.cpp



#**************************** End of makefile ******************************
