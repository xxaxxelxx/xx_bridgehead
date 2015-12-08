#!/bin/bash
cp -f iptables.addresses.players /etc/
. /etc/iptables.addresses.players

LIST_PORT="8000"
CNT=0
for PORT in $LIST_PORT; do
    for IP in $PLAYERS_ADDRESSES; do
	CNT=$(($CNT + 1));iptables -I DOCKER -i eth0 -s $IP -p tcp --dport $PORT -j ACCEPT
	CNT=$(($CNT + 1));iptables -I DOCKER -i eth0 -s $IP -p udp --dport $PORT -j ACCEPT
    done
done
for PORT in $LIST_PORT; do
    CNT=$(($CNT + 1));
    iptables -I DOCKER $CNT -i eth0 -p tcp --dport $PORT -j DROP
done
exit
