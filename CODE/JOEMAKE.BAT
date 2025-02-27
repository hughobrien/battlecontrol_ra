@echo off
timer
:***************************************************************************
:*                                                                         *
:* Network make batch file: compiles using network slaves                  *
:*                                                                         *
:* Required mods to user's AUTOEXEC:                                       *
:* - PATH should include the SLAVES directory, so make can find NETEXEC    *
:* - WWLIB should point to user's WWLIB32 installation                     *
:* - WATCOM should point to the local WATCOM root directory                *
:*                                                                         *
:* Required changes to this batch file:                                    *
:* - NETWHO should be set to the user's name                               *
:* - CCLOCALDIR & CCNETDIR should point to the local & net CC dirs         *
:*                                                                         *
:***************************************************************************
:------------------------- set up environment ------------------------------
set NETWHO=joeb
set CCLOCALDIR=c:\projects\c&czero
set CCNETDIR=f:\projects\c&c0\slaves\%NETWHO%\c&c0
set WWLIBNET=f:\projects\c&c0\slaves\%NETWHO%\wwlib32
set WATDIR=c:\projects\c&czero\code\watcom
set NETWORK=1

:------------------------- substitute drives -------------------------------
subst o: /d >&NUL
subst r: /d >&NUL
subst q: /d >&NUL
subst o: %WATDIR%
subst r: %CCLOCALDIR%
subst q: %WWLIB%

:----------------------- Set Watcom's environment --------------------------
set watcom=o:
set include=o:\h;o:\h\win;q:\include;..\vq\include;.;
set wwflat=q:
REM set wwvcs=g:\library\wwlib32\pvcswat
set DOS16M=@0--8mm

:---------------------- update network source files ------------------------
copy /s q:\include\*.h           %WWLIBNET%\include /U
copy r:\vq\include\vqm32\*.h  %CCNETDIR%\vq\include\vqm32 /U /S
copy r:\vq\include\vqa32\*.h  %CCNETDIR%\vq\include\vqa32 /U /S
copy r:\code\*.cpp r:\code\*.h r:\code\*.asm r:\code\*.i r:\code\*.inc r:\code\makefile  r:\code\*.lnk %CCNETDIR%\code /U
copy r:\code\watcom\*.* %CCNETDIR%\code\watcom /U
copy r:\code\watcom\binb\*.* %CCNETDIR%\code\watcom\binb /U
copy r:\code\watcom\binw\*.* %CCNETDIR%\code\watcom\binw /U
copy r:\code\watcom\binnt\*.* %CCNETDIR%\code\watcom\binnt /U
copy /s r:\code\watcom\h\*.* %CCNETDIR%\code\watcom\h /U
REM copy /s r:\code\watcom\*.* %CCNETDIR%\code\watcom /U
REM copy r:\code\*.h              %CCNETDIR%\code /U
REM copy r:\code\*.asm            %CCNETDIR%\code /U
REM copy r:\code\*.i              %CCNETDIR%\code /U
REM copy r:\code\*.inc            %CCNETDIR%\code /U
REM copy r:\code\makefile         %CCNETDIR%\code /U

:----------------------------- Fire up wmake -------------------------------
netexec /s
wmake /c %1 %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto makerr
goto endit

:makerr
if exist %CCNETDIR%\code\netmake.err type %CCNETDIR%\code\netmake.err

:endit
set NETWORK=

:---------------------------- Get the objects ------------------------------
copy %CCNETDIR%\code\obj\*.obj r:\code\obj /U

:***************************************************************************
timer

