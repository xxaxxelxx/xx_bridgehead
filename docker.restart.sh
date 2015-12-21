#!/bin/bash
ID=$1
test "x$ID" == "x"  && exit 1

echo "STOPPING CONTAINERS"
STOPLIST=($(docker ps | grep $ID | sed -e 's/\ *$//' | sed 's/.* //'))
for ELEM in ${STOPLIST[@]}; do
    docker stop $ELEM
done

echo "REMOVING CONTAINERS"
RMLIST=($(docker ps -a | grep $ID | sed -e 's/\ *$//' | sed 's/.* //'))
IMAGELIST=($(docker ps -a | grep $ID | awk '{print $2}'))
for ELEM in ${STOPLIST[@]}; do
    docker rm $ELEM
done

echo "PULLING IMAGES"
for ELEM in ${IMAGELIST[@]}; do
    docker pull $ELEM
done

echo "STARTING CONTAINERS"
bash RUN/${ID}*

exit