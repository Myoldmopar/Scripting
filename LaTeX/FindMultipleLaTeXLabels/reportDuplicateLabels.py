#!/usr/bin/python

import glob

labelsFound = []

for tex in glob.glob("./*.tex"):
    print tex
    lineCounter = 0
    with open(tex) as f:
        while True:
            lineCounter += 1
            line = f.readline().strip()
             
            if '\label' in line:
                postLabelText = line[line.find("\label{") + 7:]
                labelEntry = postLabelText[:postLabelText.find("}")]
                if labelEntry in labelsFound:
                    print "Encountered duplicate label:"
                    print "  Label Text = " + labelEntry
                    print "  Duplicate encountered in file = " + tex
                    print "    @ line # " + str(lineCounter)
                else:
                    labelsFound.append(labelEntry)
                    
            # couldn't read, must be done
            if not line:
                break
                
