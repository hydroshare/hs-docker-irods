#!/bin/bash

# prefetch-docker-images.sh
# Author: Michael Stealey <michael.j.stealey@gmail.com>

APPSTACK_PATH=${PWD}'/appstack'

for f in $(ls -l ${APPSTACK_PATH} | tr -s ' ' | grep "^d" | cut -d ' ' -f 9) ;
do
    echo "*** docker pull mjstealey/${f} ***"
    docker pull mjstealey/${f}
    docker tag mjstealey/${f} ${f};
done
exit;