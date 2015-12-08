#!/bin/bash
LIST_PORT="8000"
for PORT in $LIST_PORT; do
    for IP in $LIST_IP; do
	iptables -I DOCKER -i eth0 -s $1 -p tcp --dport $PORT -j ACCEPT
	iptables -I DOCKER -i eth0 -s $1 -p udp --dport $PORT -j ACCEPT
    done
done
echo "Do not forget to copy file iptables.addresses.players to /etc"
exit
