#!/bin/bash
LIST_PORT="8000"
for PORT in $LIST_PORT; do
    DETECTED_FIRST_IP="$(iptables -L DOCKER -n | grep ACCEPT | grep $PORT | awk '{print $5}' | head -n 1 | sed 's|\..*||')"
    if [ "x$DETECTED_FIRST_IP" != "x" ]; then
	DOCKERNET="$(iptables -L DOCKER -n | grep ACCEPT | grep $PORT | awk '{print $5}' | head -n 1 | sed 's|\..*||').0.0.0/8"
	iptables -v -I DOCKER -p tcp --dport $PORT ! -s $DOCKERNET -m state --state NEW -m recent -i eth0 --set --name BLOCKDOS -j ACCEPT
	iptables -v -I DOCKER -p tcp --dport $PORT ! -s $DOCKERNET -m recent -i eth0 --update --seconds 60 --hitcount 10 --rttl --name BLOCKDOS -j DROP
    fi
done
exit
