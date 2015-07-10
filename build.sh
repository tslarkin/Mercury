#!/bin/bash
set -x

# source the GNUstep stuff.
GNUSTEP_MAKEFILES=/usr/GNUstep/System/Library/Makefiles

. ${GNUSTEP_MAKEFILES}/GNUstep.sh

# libstdc++.a is in a different place on every system.
# This script SHOULD find the right one and put it in
# the Makefile, but that's not ready yet.  Do that manually.
# CLIB=`locate libstdc++.a | head -1`
#sed -i.bak 's/mercury_TOOL_LIBS *$/mercury_TOOL_LIBS \+= ${CLIB} /' GNUmakefile

make clean

make

# make errors that there is no obj/Fier/cell.d .  
# Probably that should be created elsewhere, but 
# here seems fine.

mkdir obj/Fier
make

