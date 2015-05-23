#!/bin/bash

# appstack-build.sh
# Author: Michael Stealey <michael.j.stealey@gmail.com>

APPSTACK_PATH=$1

for f in $(ls -l ${1} | tr -s ' ' | grep "^d" | cut -d ' ' -f 9) ;
do
    cd ${APPSTACK_PATH}/${f}
    CHECK_FOR_IMG=`docker images | tr -s ' ' | cut -d ' ' -f 1 | grep -Fx ${f}`
    if [[ -z "${CHECK_FOR_IMG%?}" ]]; then
        echo "*** docker build -t ${f} . ***"
        docker build -t ${f} .;
    else
        echo "*** IMG: ${f} already exists ***";
    fi
done
exit;
