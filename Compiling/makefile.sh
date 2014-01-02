#!/bin/bash

# SCRIPT METADATA
# Author:
#   Edwin Lee
# Purpose: 
#   This script will generate a make file and maybe run it based on cl args
# ChangeLog:
#   19 March 2012  **  v0.5  **  First version put in $HOME/bin to be used in Eclipse projects or otherwise
#   17 June  2013  **  v0.6  **  Generalization, trying to clean up hacks that were hardwired to Intel
#   1  Aug   2013  **  v0.7  **  Added some flags to ifort to muffle dumb remarks, trapped for bad args
# ToDo:
#   don't assume ifort will be there, use only available options...if none then error and exit
# WishList:
#   Allow project dir paths with white space (currently fails by producing a bad make file)
#    -- this will be difficult due to 'make' limitations with white space

# PROJECT BUILD FILE/DIRECTORY STRUCTURE
# root project directory (contains the final executables)
#   src subdirectory (all f90, F90, h, etc. fortran files to be compiled)
#   bin (subdirectory, no files within)
#     ifort (subdirectory, no files within)
#       debug (subdirectory, contains all mod and o files, along with the actual compiler specific makefile)
#       release (same)
#     similar for other compilers (g95, gfortran, mingw-gfortran)
# the makefile will generate the bin/compiler/configuration directory as needed
# this script should be called from the project's root directory

# OPERATION AND VARIABLES:
# see usage for command line arguments
# requires the following things on the file system
#  a perl interpreter somewhere on $PATH (this makefile will find it with "which", since it is exec)
#  the mkmf.rb script somewhere on $PATH (this makefile will find it with "whereis", since it is NOT exec)
# this script will set the following internal variables:
#  $PROJECTDIR=<the root project directory as described above>
#  $PERLPATH=<the full path to the system's perl executable>
#  $MKMFPATH=<the full path to the mkmf.rb script, somewhere on path>
# this script will export the following symbols
#  $FC=<compiler exec>
#  $LD=<linker exec> 
#  $FFLAGS=<compiler options>
#  $LDFLAGS=<linker options>

{ # ERROR RETURN CODES
ERR_PERLNOTFOUND=101
ERR_MKMFNOTFOUND=102
ERR_NOSOURCEDIRECTORY=103
ERR_WHITESPACEINPATH=104
ERR_BADARGUMENT=105
}

# this is a simple function to output stuff conditionally based on VERBOSE=Y/N
function f_out() {
    if [ "$VERBOSE" == "Y" ]; then
        echo "+-+ $1"
    fi    
}

# this function will export symbols for a single compiler-configuration set
# the function accepts two arguments: $1=compiler, $2=configuration
function export_symbols() {

    # the specific compiler and configuration (compiler switches) can be set here based on FCOMPILER and FCONFIG

    if [ "$1" == "ifort" ]; then
        
        export FC="ifort" 
        export LD="ifort" 
        
        if [ "$2" == "debug" ]; then
        
              #### these are for intel compiler/debug config
            export FFLAGS="-O0 -traceback -DLINUX -fpp -fpe0 -g -I /usr/include -diag-disable 8290 -diag-disable 8291"
            export LDFLAGS="-O0 -g -B /usr/lib"

        elif [ "$2" == "release" ]; then

              #### these are for intel release
            export FFLAGS="-O3 -DLINUX -fpp -fpe0 -I /usr/include -diag-disable 8290 -diag-disable 8291"
            export LDFLAGS="-O3 -B /usr/lib"
      
        fi

    elif [ "$1" == "g95" ]; then

        export FC="g95"
        export LD="g95"
                
        if [ "$2" == "debug" ]; then
        
              #### these are g95 debug
            export FFLAGS="-O0 -DLINUX -cpp -g -I /usr/include -ffree-line-length-huge"
            export LDFLAGS="-O0 -g -B /usr/lib -B /usr/lib/x86_64-linux-gnu"

        elif [ "$2" == "release" ]; then

              #### these are g95 release
            export FFLAGS="-O3 -DLINUX -cpp -I /usr/include -ffree-line-length-huge"
            export LDFLAGS="-O3 -B /usr/lib -B /usr/lib/x86_64-linux-gnu"

        fi
                    
    elif [ "$1" == "gfortran" ]; then

        export FC="gfortran"
        export LD="gfortran"
            
        if [ "$2" == "debug" ]; then 
        
              #### these are gfortran debug
            export FFLAGS="-O0 -DLINUX -cpp -g -I /usr/include -ffree-line-length-300"
            export LDFLAGS="-O0 -g -B /usr/lib"

        elif [ "$2" == "release" ]; then

              #### these are gfortran release
            export FFLAGS="-O3 -DLINUX -cpp -I /usr/include -ffree-line-length-300"
            export LDFLAGS="-O3 -B /usr/lib"

        fi
                
    elif [ "$1" == "mingw" ]; then

        export FC="x86_64-w64-mingw32-gfortran"
        export LD="x86_64-w64-mingw32-gfortran"
            
        if [ "$2" == "debug" ]; then
        
              #### these are for mingw debug
            export FFLAGS="-O0 -DLINUX -g -cpp -I /usr/include -ffree-line-length-300"
            export LDFLAGS="-O0 -g -B /usr/lib -static-libgcc -static-libgfortran"

        elif [ "$2" == "release" ]; then
        
              #### these are for mingw release
            export FFLAGS="-O3 -DLINUX -cpp -I /usr/include  -ffree-line-length-300"
            export LDFLAGS="-O3 -B /usr/lib -static-libgcc -static-libgfortran"

        fi
                
    fi
    
    f_out "Encountered the following compiler/config pair: $1/$2"
    f_out "Exported the following compiler/linker variables:"
    f_out "FC = $FC"
    f_out "LD = $LD"
    f_out "FFLAGS = $FFLAGS"
    f_out "LDFLAGS = $LDFLAGS"

}

# this function displays usage instructions for the user
function usage() {
    
    local THISFILE=$(basename $0)
    local TAB=$( printf "\t" )
    local THISFOLDER=`echo ${PWD##*/}`
    echo "usage: $THISFILE  [-s] [-c <COMPILER>] [-f <CONFIGURATION>] [-t <TARGET>] [-n <PROJECTNAME>]"
    echo " "
    echo " Use this script to create make files, and build executables as needed for a given fortran project"
    echo " Call this script from the project's working directory"
    echo " Default* entries* are* denoted* with* asterisks*"
    echo " "
    echo "   -h (HELP)     $TAB show this message"
    echo "   -c (COMPILER) $TAB builds the project using the entired compiler, valid entries are:"
    if [ ! -z `which ifort` ]; then
    echo "                 $TAB   ifort*   $TAB (intel fortran compiler)"
    fi
    if [ ! -z `which g95` ]; then
    echo "                 $TAB   g95      $TAB (g95 fortran compiler)"
    fi
    if [ ! -z `which gfortran` ]; then
    echo "                 $TAB   gfortran $TAB (gfortran fortran compiler)"
    fi
    if [ ! -z `which x86_64-w64-mingw32-gfortran` ]; then
    echo "                 $TAB   mingw    $TAB (mingw *Windows* gfortran fortran compiler)"
    fi  
    echo "                 $TAB   all      $TAB (builds with all available fortran compilers)"
    echo "   -s (SPLIT)    $TAB if this is used, the build will be disowned from this console"
    echo "                 $TAB if multiple build configs/compilers are used, these will then be threaded"
    echo "   -f (CONFIG)   $TAB builds the entered configuration, valid entries are:"
    echo "                 $TAB   debug*   $TAB (builds unoptimized code with debug symbols)"
    echo "                 $TAB   release  $TAB (builds optimized code)"
    echo "                 $TAB   all      $TAB (builds both debug and release executables)"
    echo "   -t (TARGET)   $TAB performs the given operation, valid entries are:"
    echo "                 $TAB   makemake $TAB (creates the make file only)"
    echo "                 $TAB   clean    $TAB (deletes intermediate files)"
    echo "                 $TAB   build*   $TAB (creates the make file and builds)"
    echo "                 $TAB   rebuild  $TAB (performs clean then build operations)"
    echo "   -n (NAME)     $TAB the project name to use for creating the executable"
    echo "                 $TAB   <string> $TAB (DEFAULT is the current folder name \"$THISFOLDER\")"
    echo "   -d (DONTMAKE) $TAB skips the makefile generation step, overridden by \"-t makemake\""
    echo "   -v (VERBOSE)  $TAB spew much more output"
    echo " "
    echo "Examples:"
    echo "1) Build with defaults (ifort, debug, build, myproject)"
    echo "  $THISFILE"
    echo " "
    echo "2) Create a g95 release make file for project EnergyMinus"
    echo "  $THISFILE -c g95 -f release -t makemake -n EnergyMinus"
    echo " "
    echo "3) Rebuild all available compiler debug execs, thread the operations separately, pass all output to a log file"
    echo "  $THISFILE -c all -f debug -t rebuild -s > build-$(date +%Y-%m-%d).log"
    
}

###### MAIN OPERATION ######

  # process command line arguments
FCOMPILER=ifort
FCONFIG=debug
FTARGET=build
PROJECTNAME=`echo ${PWD##*/}`
FORK=N
SKIPMAKINGMAKE=N
VERBOSE=N
while getopts "vhdsc:f:t:n:" OPTION; do
    case $OPTION in
        h) 
            usage
            exit 1
            ;;
        c)  
            if [ "$OPTARG" == "all" ]; then 
                FCOMPILER=""
                if [ ! -z `which ifort` ]; then
                    FCOMPILER="${FCOMPILER} ifort"
                fi
                if [ ! -z `which g95` ]; then
                    FCOMPILER="${FCOMPILER} g95"
                fi
                if [ ! -z `which gfortran` ]; then
                    FCOMPILER="${FCOMPILER} gfortran"
                fi
                if [ ! -z `which x86_64-w64-mingw32-gfortran` ]; then
                    FCOMPILER="${FCOMPILER} mingw"
                fi      
            else
                FCOMPILER=$OPTARG
            fi
            f_out "Processed command line option \"$OPTION\""
            ;;
        f)
            if [ "$OPTARG" == "all" ]; then
                FCONFIG="debug release"
            else
                FCONFIG=$OPTARG
            fi
            if [[ ! "debug release" =~ $FCONFIG ]]; then
                echo "Bad configuration entered...must be either debug or release"
                exit $ERR_BADARGUMENT
            fi
            f_out "Processed command line option \"$OPTION\""
            ;;
        t)
            FTARGET=$OPTARG
            if [[ ! "makemake clean build rebuild" =~ $FTARGET ]]; then
                echo "Bad target, must be one of: makemake, clean, build, or rebuild"
                exit $ERR_BADARGUMENT
            fi
            f_out "Processed command line option \"$OPTION\""
            ;;
        n)
            PROJECTNAME=$OPTARG
            f_out "Processed command line option \"$OPTION\""
            ;;
        s)  
            FORK=Y
            f_out "Processed command line option \"$OPTION\""
            ;;
        d)
            SKIPMAKINGMAKE=Y
            f_out "Processed command line option \"$OPTION\""
            ;;
        v)
            VERBOSE=Y
            f_out "Processed command line option \"$OPTION\""
            ;;
        ?)
            usage
            exit
            ;;
    esac    
done
  
  # get the present (project) directory
PROJECTDIR=`pwd`
f_out "Project directory found at: $PROJECTDIR"

  # check to make sure path doesn't have white space...a current limitation
#case $PROJECTDIR in 
    #*\ *) 
        #echo "White space encountered in project path...makefiles don't exactly support white space (or commas)."
        #echo "A workaround is to symlink to here from a white-space-clean path"
        #exit $ERR_WHITESPACEINPATH
        #;;  
    #*) 
        ## no white space found...we're good
        #f_out "Project directory found to be white-space-free, moving on..."
        #;; 
#esac

  # check to make sure source directory is present before doing anything else
if [ ! -d "${PROJECTDIR}/src" ]; then
    echo "Could not find src subdirectory in current directory...current dir=\"${PROJECTDIR}\""
    exit $ERR_NOSOURCEDIRECTORY
else
    f_out "Found the src subdirectory, moving on..."
fi

  # this script is going to call perl to run the mkmf script, find perl
PERLPATH=`which perl` 
if [ -z ${PERLPATH} ]; then
    echo "Could not find Perl, either not installed on this machine or not on $PATH...script aborting"
    exit $ERR_PERLNOTFOUND
else
    f_out "Found the path to a perl executable, moving on..."
fi
      
  # get mkmf path here, trim white space
  ### NOTE THAT WHICH ONLY WORKS IF IT IS EXECUTABLE
MKMFPATH=`which mkmf.rb` 
if [ -z ${MKMFPATH} ]; then
    echo "Could not find mkmf.rb, either not available on this machine or not on $PATH...script aborting"
    exit $ERR_MKMFNOTFOUND
else
    f_out "Found the mkmf.rb file, moving on..."
fi
   
  # now determine what to actually do here, the command line argument processor will have filled these arrays appropriately
for COMP in $FCOMPILER; do
    for CONF in $FCONFIG; do

          # set the working directory where the makefile and intermediate files will/would/do reside
        WORKINGDIR=$PROJECTDIR/bin/$COMP/$CONF
        if [ ! -d "${WORKINGDIR}" ]; then
            mkdir -p "${WORKINGDIR}"
        fi   
       
          # export the symbols for this compiler configuration
        export_symbols $COMP $CONF

          # you will make a makefile everytime except one case: -d flag is given (SKIPMAKINGMAKE=Y) +-+ AND +-+ -t is NOT MAKEMAKE ("$FTARGET" != "makemake")
        if [ "$SKIPMAKINGMAKE" == Y ] && [ "$FTARGET" != "makemake" ]; then
            #skip making the make file
            f_out "Skipped making the make file"
        else
            #do make the make file for all other cases
            if [ "$COMP" == "mingw" ]; then
                ${PERLPATH} -- "${MKMFPATH}" -a "$PROJECTDIR/src" -p "$PROJECTDIR/${PROJECTNAME}_${COMP}_${CONF}.exe" -m "${WORKINGDIR}/makefile"
            else
                ${PERLPATH} -- "${MKMFPATH}" -a "$PROJECTDIR/src" -p "$PROJECTDIR/${PROJECTNAME}_${COMP}_${CONF}" -m "${WORKINGDIR}/makefile"
            fi
        fi

          # if we just needed to make a make file, then we are done
        if [ "$FTARGET" == "makemake" ]; then
            echo "Make file created...exiting"
            exit 0
        fi

          # if we are cleaning or rebuilding, we need to do a clean
        if [ "$FTARGET" == "clean" ] || [ "$FTARGET" == "rebuild" ]; then
            echo "cleaning working directory"
            make -C "${WORKINGDIR}" clean
            rm -rf " ${WORKINGDIR}"/*.mod
        fi

          # if we are building or rebuilding, we need to do a build
        if [ "$FTARGET" == "build" ] || [ "$FTARGET" == "rebuild" ]; then
            if [ "$FORK" == "Y" ]; then
                make -C "${WORKINGDIR}" all & disown
            else
                make -C "${WORKINGDIR}" all
            fi
        fi      
        
    done
done

