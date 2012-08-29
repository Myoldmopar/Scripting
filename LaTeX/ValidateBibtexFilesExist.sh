#!/bin/bash
for fn in `grep 'file =' Database.bib | cut -d : -f 2`
do
    [ -f "$fn" ] || "NO: $fn" 
done
