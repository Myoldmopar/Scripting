#!/bin/bash

# process given command line
MYNAME=$0
CALLTYPE=`echo $1 | tr '[:lower:]' '[:upper:]'`

# check the validity of the call type
VALIDCALLS="PLAYPAUSE SKIP INFO"
if [[ $VALIDCALLS =~ $CALLTYPE ]]; then
    echo "Incoming call exists in valid list"
else
    echo "Incoming call does not exist in valid list!"
    echo "Incoming call = ${CALLTYPE}"
    echo "Valid list = ${VALIDCALLS}"
    exit 1
fi

# setup the org.domain.interface.method signal
if [ "a${CALLTYPE}" == "aPLAYPAUSE" ]; then
    SIGNAL=net.kevinmehall.Pithos.PlayPause
elif [ "a${CALLTYPE}" == "aSKIP" ]; then
    SIGNAL=net.kevinmehall.Pithos.SkipSong
elif [ "a${CALLTYPE}" == "aINFO" ]; then
    SIGNAL=net.kevinmehall.Pithos.GetCurrentSong
fi

# send the signal on the bus
dbus-send --print-reply --dest=net.kevinmehall.Pithos /net/kevinmehall/Pithos "${SIGNAL}"
