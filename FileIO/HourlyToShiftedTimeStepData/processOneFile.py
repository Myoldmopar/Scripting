#!/usr/bin/python

import sys
import string

lineCounter = 0
numTimeStepsPerHour = 4

# get the number of rows in the file    
fName = sys.argv[1]

with open(fName) as f:
    for numLines, l in enumerate(f):
        pass    

# re open the file and start reading
with open(fName) as f:

    while True:
        lineCounter += 1
        line = f.readline().strip()
        
        # couldn't read, must be done
        if not line:
            break
            
        # we are on the header, just re-spew it
        if lineCounter == 1:
            print line
        # we are on the first set of data, we only want to output (numTimeStepsPerHour-1) in order to shift it
        elif lineCounter == 2:
            for i in range(numTimeStepsPerHour-1):
                print line
        # check for the last line also, since we need an extra row
        elif lineCounter == numLines:
            for i in range(numTimeStepsPerHour+1):
                print line
        # we must be on a regular line    
        else:
            for i in range(numTimeStepsPerHour):
                print line
