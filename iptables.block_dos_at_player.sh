#!/bin/bash
LIST_PORT="8000"
for PORT in $LIST_PORT; do
    DOCKERNET="$(iptables -L DOCKER -n | grep ACCEPT | grep $PORT | awk '{print $5}' | head -n 1 | sed 's|\..*||').0.0.0/8"
#    iptables -v -I DOCKER -p tcp --dport $PORT ! -s $DOCKERNET -m recent -i eth0 --update --seconds 60 --hitcount 10 --rttl -j DROP
    iptables -v -I DOCKER -p tcp --dport $PORT -m state --state NEW -m recent -i eth0 --set --name BLOCKDOS -j ACCEPT
    iptables -v -I DOCKER -p tcp --dport $PORT -m recent -i eth0 --update --seconds 60 --hitcount 3 --rttl --name BLOCKDOS -j DROP
done
exit

#iptables -A service_attack -p tcp --dport 80 -m recent -i eth0 --update --seconds 60 --hitcount 10 --rttl --name ICECAST -j DROP
#iptables -A service_attack -p tcp --dport 80 -m state --state NEW -m recent -i eth0 --set --name ICECAST -j ACCEPT

