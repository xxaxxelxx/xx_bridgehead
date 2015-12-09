#!/bin/bash
LIST_PORT="8000"
for PORT in $LIST_PORT; do
    DOCKERNET="$(iptables -L DOCKER -n | grep $PORT | awk '{print $5}' | head -n 1 | sed 's|\..*||').0.0.0/8"
    iptables -v -I DOCKER -p tcp --dport $PORT ! -s $DOCKERNET -m recent -i eth0 --update --seconds 60 --hitcount 10 --rttl -j DROP
done
exit
