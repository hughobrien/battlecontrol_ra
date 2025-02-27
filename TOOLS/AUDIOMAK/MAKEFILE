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

.AUTODEPEND

OBJECTS = audiomak.obj scode.obj

.cpp.obj:
	bcc {$*.cpp }

.asm.obj:
	tasm $<,$&.obj
	
audiomak.exe: turboc.cfg tasm.cfg tlink.cfg $(OBJECTS)
	tlink @&&!
	c0l.obj $(OBJECTS)
	audiomak.exe
	audiomak.map
	CL.LIB MATHL.LIB EMU.LIB
!


####################################################################
# Creates the TURBOC configuration file (also affects CPP.EXE)
turboc.cfg: makefile
	copy &&!
 -v					# Debugging output.
 -y
 -Vt					# Virtual table pointer comes at end of class members (NEVER CHANGE).
 -Vb-					# Always near pointer to virtual table.
 -a-					# Structures are packed (not byte aligned).
 -b-					# Enums as small as possible.
 -3				   # Enable 386 instructions.
 -ml					# Large model.
 -C-					# Don't allow nested comments (DON'T CHANGE THIS).
 -c					# Just compile -- don't link.
 -Jg					# Template instances are merged to avoid duplicates.
 -Id:\bc4\include	# Header search path.
 -P-					# If extension = .CPP then compile as C++, otherwise treat as C.
 -w					# Enable all warnings.
# -w!					# Treat all warnings as errors.
 -X-					# Turn on autodependency checking.
 -RT					# Enable run time type itentification.
 -x					# Enable exception handling code.
 -k-					# Optimize: Use abbreviated stack frame.
 -vi					# Turns "inline" expansion on.
 -Z					# Optimize: Supress redundant register loads.
 -Oi					# Optimize: Helper functions expanded inline.
 -O					# Optimize: Jump optimization.
 -Op					# Optimize: Copy propagation to supress reloads.
 -Ov					# Optimize: Speeds array indexing inside of loops.
 -Og					# Optimize: Eliminates common subexpressions (globally).
 -Oc					# Optimize: Eliminates common subexpressions (locally).
 -Ol					# Optimize: Use REP instruction where possible.
 -d					# Optimize: Duplicate strings are merged.
 -r					# Try to put auto variables into registers.
 -V					# Use smart virtual tables (only usable with BCC and TLINK).
 -dc-					# Keep strings in the data segment (DON'T CHANGE THIS).
 -Ff					# Put very very large objects into the far segment.
 -K2-					# Treat "char" different from "signed char" or "unsigned char".
 -Oa					# Optimize: Assumes no pointer aliasing (could cause bugs)!
 -R-					# Don't include browser data (only used by IDE).
# -Oe					# Optimize: Global register allocation tracking enabled.
# -Ob					# Optimize: Dead code elimination.
# -Om					# Optimize: Remove invariant code from loops.
# -p					# Pascal calling convention default.
# -pr					# Regiser calling convention default.
# -po					# Pass "this" in registers when calling member functions.
# -f-					# Floating point prohibited.
# -Yo					# Compile as overlay module.
# -Ox					# Optimize: Execution speed.
! turboc.cfg /Q

####################################################################
# Creates TASM config file.
tasm.cfg: makefile
	copy &&!
 /Zi					# Include debug information into object file.
 /w+ICG
 /w-PDC
 /t
 /w2					# Maximum warning level.
 /ml 					# Large model.
 /w+
 /v
 /JIDEAL 			# Ideal mode.
 /JP386N				# Enable 386 instructions.
 /UT300				# Force compatibility with old TASM.
! tasm.cfg

####################################################################
# Creates the TLINK.CFG file which implicitly controls linking.
tlink.cfg: makefile
	copy &&!
 /Ld:\bc4\lib
 /v 
 /c 
 /e
 /Tde 
! tlink.cfg /Q

