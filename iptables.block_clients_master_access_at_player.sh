#!/bin/bash
LIST_PORT="8000"
for PORT in $LIST_PORT; do
    DETECTED_FIRST_IP="$(iptables -L DOCKER -n | grep ACCEPT | grep $PORT | awk '{print $5}' | head -n 1 | sed 's|\..*||')"
    if [ "x$DETECTED_FIRST_IP" != "x" ]; then
	DOCKERNET="$DETECTED_FIRST_IP.0.0.0/8"
	iptables -v -I DOCKER -i eth0 -p tcp --dport $PORT ! -s $DOCKERNET -m string --algo bm --string "_master" -j DROP 
    fi
done
exit
