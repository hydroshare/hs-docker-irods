#!/bin/bash

# appstack-build.sh
# Author: Michael Stealey <michael.j.stealey@gmail.com>

APPSTACK_PATH=$1

for f in $(ls -l ${1} | tr -s ' ' | grep "^d" | cut -d ' ' -f 9)
do
    echo "*** docker build -t ${f} . ***"
    cd ${APPSTACK_PATH}/${f}
    docker build -t ${f} .;
done