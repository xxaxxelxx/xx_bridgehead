#!/bin/bash
ID=$1
test "x$1" == "x"  && exit 1

STOPLIST=($(docker ps | grep "^$1"))


exit