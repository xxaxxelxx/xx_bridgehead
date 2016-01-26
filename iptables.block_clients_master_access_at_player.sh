#!/bin/bash
LIST_PORT="8000"
DOCKER_NET="172.17.0.0/16"
for PORT in $LIST_PORT; do
    if [ "x$DETECTED_FIRST_IP" != "x" ]; then
	iptables -v -I DOCKER -i eth0 -p tcp --dport $PORT ! -s $DOCKER_NET -m string --algo bm --string "_master" -j DROP 
    fi
done
exit
