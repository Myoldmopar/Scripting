#!/bin/bash

# check if it is root, since only root can modprobe the kernel
if [ ! "`whoami`" = "root" ]; then
    zenity --error --text "Error, Logitech mouse kernel driver probing must be done by root (sudo).  Aborting..."
    exit 1
fi

# send a message that the plug should probably be unplugged and replugged...may need to re-probe after this
notify-send 'Don'"'"'t forget to un/re-plug antenna' -i /home/elee/Pictures/MouseShadow.png

# now do the driver injection
modprobe -r hid_logitech_dj && modprobe hid_logitech_dj
