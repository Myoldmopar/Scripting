#!/usr/bin/python

# this script manipulates the IDF object to increase the length of refrigerated cases

import sys
import string

# set up some constants...string matches
matchCaseLength = "!- Case Length {m}"  # on the refrigeration case objects
matchWalkInArea = "!- Insulated Floor Surface Area {m2}" # on the walk in

# get the file name
fName = sys.argv[1]

# get the fractional adjustment to case length and walk in square footage
changeFrac = float(sys.argv[2])

# re open the file and start reading
with open(fName) as f:

    while True:
        lineRaw = f.readline()
        
        # couldn't read, must be done
        if len(lineRaw) == 0:
            break
        
        # strip it as necessary
        line = lineRaw.strip()
        
        # check if we have a match of any kind, both changes are the same process
        if matchCaseLength in line or matchWalkInArea in line:
            tokens = line.split(",")
            val = float(tokens[0].strip())
            val *= changeFrac
            outLine = str(val) + "," + str(tokens[1])
        else:
            outLine = line

        print outLine
