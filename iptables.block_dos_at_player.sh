#!/bin/bash
LIST_PORT="8000"
DOCKER_NET="172.17.0.0/16"
for PORT in $LIST_PORT; do
    if [ "x$DETECTED_FIRST_IP" != "x" ]; then
	iptables -v -I DOCKER -p tcp --dport $PORT ! -s $DOCKER_NET -m state --state NEW -m recent -i eth0 --set --name BLOCKDOS -j ACCEPT
	iptables -v -I DOCKER -p tcp --dport $PORT ! -s $DOCKER_NET -m recent -i eth0 --update --seconds 60 --hitcount 10 --rttl --name BLOCKDOS -j DROP
    fi
done
exit



exit
