#!/bin/bash
LIST_PORT="8000"
for PORT in $LIST_PORT; do
	iptables -v -I DOCKER -i eth0 -s $1 -p tcp --dport $PORT -j ACCEPT
	iptables -v -I DOCKER -i eth0 -s $1 -p udp --dport $PORT -j ACCEPT
done
echo "Do not forget to add this address to iptables.addresses.players and to copy this file to /etc"
exit
