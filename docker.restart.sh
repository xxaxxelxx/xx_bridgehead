#!/bin/bash
ID=$1
test "x$ID" == "x"  && exit 1

STOPLIST=($(docker ps | grep '^$ID'))

for ELEM in ${STOPLIST[@]}; do
    echo $ELEM
done


exit