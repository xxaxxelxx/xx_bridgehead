#!/bin/bash
LIST_PORT="8000"
LIST_IP="141.16.140.18/32 78.46.212.105/32 78.47.230.110/32"
CNT=0
for PORT in $LIST_PORT; do
    for IP in $LIST_IP; do
	CNT=$(( $CNT + 1 ));iptables -I DOCKER -i eth0 -s $IP -p tcp --dport $PORT -j ACCEPT
	CNT=$(( $CNT + 1 ));iptables -I DOCKER -i eth0 -s $IP -p udp --dport $PORT -j ACCEPT
    done
done
CNT=$(( $CNT + 1 ))
iptables -I DOCKER $CNT -i eth0 -p tcp --dport $PORT -j DROP
exit
