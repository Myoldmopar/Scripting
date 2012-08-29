#!/bin/bash

for DIR in $(find . -name Unsorted -type d); do
	if [ "$(ls -A $DIR)" ]; then
		echo "Found unsorted papers in: $DIR"
	fi
done

