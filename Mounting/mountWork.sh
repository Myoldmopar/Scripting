#!/bin/bash

# To Do:
# Generalize to loops...no need to repeat this stuff over and over
# Add appindicator/desktopFile/launcher support

# error check the command line first
if [ $# != 1 ]; then
    zenity --error --text="Invalid number of arguments in call to myMount tool"
    exit 1
else
    ARGTYPE=`echo $1 | tr '[:lower:]' '[:upper:]'`
    if [ "x${ARGTYPE}" == "xUMOUNT" ]; then
        UNMOUNTONLY=Y
    elif [ "x${ARGTYPE}" == "xMOUNT" ]; then
        UNMOUNTONLY=N
    else
        zenity --error --text="Invalid argument in call to myMount tool: must be \"mount\" or \"umount\""
        exit 1
    fi
fi

# set up some parameters
THISUSER="${USER}"
THISUID="${UID}"

# define local mount points and the domain name
MOUNTPOINTHOME=`head -1 ${HOME}/Programs/Scripting/Mounting/mountPaths | tail -1`
MOUNTPOINTSHARE=`head -2 ${HOME}/Programs/Scripting/Mounting/mountPaths | tail -1`
MOUNTPOINTCBI=`head -3 ${HOME}/Programs/Scripting/Mounting/mountPaths | tail -1`
THISDOMAIN=`head -1 ${HOME}/Programs/Scripting/Mounting/domainName | tail -1`

# initialize the output message and run status for notify
DOSOMETHING=N
MSG=""

# check if we need to do anything first
if [ "${UNMOUNTONLY}" == "Y" ]; then
    # home
    if mountpoint -q "${MOUNTPOINTHOME}"; then
        DOSOMETHING=Y
    fi
    # shared
    if mountpoint -q "${MOUNTPOINTSHARE}"; then
        DOSOMETHING=Y
    fi
    # cbi specific
    if mountpoint -q "${MOUNTPOINTCBI}"; then
        DOSOMETHING=Y
    fi
else
    # home
    if ! mountpoint -q "${MOUNTPOINTHOME}"; then
        DOSOMETHING=Y
    fi
    # shared
    if ! mountpoint -q "${MOUNTPOINTSHARE}"; then
        DOSOMETHING=Y
    fi
    # cbi specific
    if ! mountpoint -q "${MOUNTPOINTCBI}"; then
        DOSOMETHING=Y
    fi
fi

if [ "${DOSOMETHING}" == "N" ]; then # nothing to do

    MSG="Nothing to do...all done!"

else # need to do something

    # get the sudo password
    SUDOPASS=`zenity --entry --title="Password" --text="Enter Sudo Password:" --hide-text`
    if [ $? != 0 ]; then
        zenity --error --text="Error getting Sudo password, aborting..."
        exit 1
    fi

    # if we are unmounting, then we don't need to do much
    if [ "${UNMOUNTONLY}" == "Y" ]; then
        # home
        if mountpoint -q "${MOUNTPOINTHOME}"; then
            echo "${SUDOPASS}" | sudo -S umount "${MOUNTPOINTHOME}" && MSG+="${MOUNTPOINTHOME}: Unmounted\n"  || MSG+="${MOUNTPOINTHOME}: Couldn't unmount\n"
        else
            MSG+="${MOUNTPOINTHOME}: Didn't need to unmount\n"
        fi
        # shared
        if mountpoint -q "${MOUNTPOINTSHARE}"; then
            echo "${SUDOPASS}" | sudo -S umount "${MOUNTPOINTSHARE}" && MSG+="${MOUNTPOINTSHARE}: Unmounted\n"  || MSG+="${MOUNTPOINTSHARE}: Couldn't unmount\n"
        else
            MSG+="${MOUNTPOINTSHARE}: Didn't need to unmount\n"
        fi
        # cbi specific
        if mountpoint -q "${MOUNTPOINTCBI}"; then
            echo "${SUDOPASS}" | sudo -S umount "${MOUNTPOINTCBI}" && MSG+="${MOUNTPOINTCBI}: Unmounted\n"  || MSG+="${MOUNTPOINTCBI}: Couldn't unmount\n"
        else
            MSG+="${MOUNTPOINTCBI}: Didn't need to unmount\n"
        fi

    else # mounting

        # if we are mounting, we need to make sure folders exist...also alert that the folder should be owned
        if [ ! -d "${MOUNTPOINTHOME}" ]; then
            zenity --error --text="A mount point doesn't exist: ${MOUNTPOINTHOME}.  This should already exist and (most likely) be owned by ${THISUSER}"
            exit 1
        fi
        if [ ! -d "${MOUNTPOINTSHARE}" ]; then
            zenity --error --text="A mount point doesn't exist: ${MOUNTPOINTSHARE}.  This should already exist and (most likely) be owned by ${THISUSER}"
            exit 1
        fi
        if [ ! -d "${MOUNTPOINTCBI}" ]; then
            zenity --error --text="A mount point doesn't exist: ${MOUNTPOINTCBI}.  This should already exist and (most likely) be owned by ${THISUSER}"
            exit 1
        fi

        # define remote mount shares
        SERVERHOME=`head -1 ${HOME}/Programs/Scripting/Mounting/serverPaths | tail -1`
        SERVERSHARE=`head -2 ${HOME}/Programs/Scripting/Mounting/serverPaths | tail -1`
        SERVERCBI=`head -3 ${HOME}/Programs/Scripting/Mounting/serverPaths | tail -1`

        # get the mount password
        MOUNTPASS=`zenity --entry --title="Password" --text="Enter Mount Password:" --hide-text`
        if [ $? != 0 ]; then
            zenity --error --text="Error getting mount password, aborting..."
            exit 1
        fi

        # start mounting with home
        if ! mountpoint -q "${MOUNTPOINTHOME}"; then
            echo "${SUDOPASS}" | sudo -S mount.cifs "${SERVERHOME}"  "${MOUNTPOINTHOME}"  -o user="${THISUSER}",pass="${MOUNTPASS}",domain="${THISDOMAIN}",uid="${THISUID}",rw && MSG+="${MOUNTPOINTHOME}: Mounted\n"  || MSG+="${MOUNTPOINTHOME}: Couldn't mount\n"
        else
            MSG+="${MOUNTPOINTHOME}: already mounted\n"
        fi
        # shared
        if ! mountpoint -q "${MOUNTPOINTSHARE}"; then
            echo "${SUDOPASS}" | sudo -S mount.cifs "${SERVERSHARE}" "${MOUNTPOINTSHARE}" -o user="${THISUSER}",pass="${MOUNTPASS}",domain="${THISDOMAIN}",uid="${THISUID}",rw && MSG+="${MOUNTPOINTSHARE}: Mounted\n"  || MSG+="${MOUNTPOINTSHARE}: Couldn't mount\n"
        else
            MSG+="${MOUNTPOINTSHARE}: already mounted\n"
        fi
        # cbi specific
        if ! mountpoint -q "${MOUNTPOINTCBI}"; then
            echo "${SUDOPASS}" | sudo -S mount.cifs "${SERVERCBI}"   "${MOUNTPOINTCBI}"   -o user="${THISUSER}",pass="${MOUNTPASS}",domain="${THISDOMAIN}",uid="${THISUID}",rw && MSG+="${MOUNTPOINTCBI}: Mounted\n"  || MSG+="${MOUNTPOINTCBI}: Couldn't mount\n"
        else
            MSG+="${MOUNTPOINTCBI}: already mounted\n"
        fi

    fi #MOUNT=Y/N

fi #DOSOMETHING=Y/N

notify-send --urgency=critical --icon="/home/elee/Pictures/ShareIcon.png" "`basename ${0}` Update" "${MSG}"
