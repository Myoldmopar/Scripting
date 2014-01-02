#!/bin/bash

for i in *.csv; do
    echo $i
    ./processOneFile.py $i > "`basename $i .csv`_PreCorrected.csv"
done
