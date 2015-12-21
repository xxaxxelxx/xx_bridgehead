#!/bin/bash
ID=$1
test "x$1" == "x"  && exit 1

STOPLIST=($(docker ps | grep "^$1"))

for ELEM in ${STOPLIST[@]}; do
    echo $ELEM
done


exit