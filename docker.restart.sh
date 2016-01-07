#!/bin/bash

while test "x$1" != "x"; do
    ID=$1

    echo "STOPPING CONTAINERS"
    STOPLIST=($(docker ps | grep $ID | sed -e 's/\ *$//' | sed 's/.* //'))
    for ELEM in ${STOPLIST[@]}; do
	docker stop $ELEM
    done

    echo "REMOVING CONTAINERS"
    RMLIST=($(docker ps -a | grep $ID | sed -e 's/\ *$//' | sed 's/.* //'))
    IMAGELIST=($(docker ps -a | grep $ID | awk '{print $2}' | sort -u))
    for ELEM in ${STOPLIST[@]}; do
	docker rm $ELEM
    done

    echo "PULLING IMAGES"
    for ELEM in ${IMAGELIST[@]}; do
	docker pull $ELEM
    done

    echo "STARTING CONTAINERS"
    for FILE in RUN/${ID}*; do
	cat $FILE | bash
    done
    shift
done

exit