#!/bin/bash

echo " ** ** ** ** SEARCHING FOR LONG LINES ** ** ** ** "
for file in *; do
    output=`awk '{if (length>132) {print NR, ": ", $0}}' $file`
    if [ ! -z "${output}" ]; then
        numLines=`echo "$output" | wc -l`
        echo ""
        echo "****************************************"
        echo -e "Current file:\t$file"
        echo -e "  # Lines greater than 132: ${numLines}"
        echo "****************************************"
        echo "${output}"
    fi
done

echo "\n ** ** ** ** SEARCHING FOR TABS ** ** ** ** "
grep -nP '\t' *.f90
