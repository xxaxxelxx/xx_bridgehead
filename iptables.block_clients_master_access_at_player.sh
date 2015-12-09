#!/bin/bash
LIST_PORT="8000"


for PORT in $LIST_PORT; do
    DOCKERNET="$(iptables -L DOCKER -n | grep $PORT | awk '{print $5}' | head -n 1 | sed 's|\..*||').0.0.0/8"
echo $DOCKERNET
#    iptables -I DOCKER -i eth0 -p tcp --dport $PORT ! -s $DOCKERNET -m string --algo bm --string "_master" -j DROP 
exit
