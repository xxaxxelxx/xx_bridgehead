#!/bin/bash

SLEEP=60
REFLECT_AT=3
REFLECTLIMIT=80
ACCEPT_AT=3
ACCEPTLIMIT=80
PULSEFILE=/tmp/pulse.cpuload
LOGFILE=/root/reflect.log
REFCNT=0
ACCCNT=0
STATUS="ACCEPT"

FORCE="$1"


if [ "x$FORCE" == "xR" ]; then
    test -r /root/loadbalancer.addr
    if [ $? -eq 0 ]; then
	LOADBALANCER=$(cat /root/loadbalancer.addr)
	docker stop reflector; docker rm reflector
	docker run -d --name reflector -e TARGET_SERVER=$LOADBALANCER -e TARGET_PORT=80 -p 80:80 --restart=always xxaxxelxx/xx_reflector
	iptables -t nat -I DOCKER 1 -p tcp --dport 8000 -j DNAT --to-destination $(iptables -n -L DOCKER | grep -w dpt:80 | awk '{print $5}'):80
	exit
    fi
elif [ "x$FORCE" == "xA" ]; then
    iptables -t nat -D DOCKER $(iptables -t nat -L DOCKER --line-numbers | grep -w dpt:8000 | grep ':80$' | awk '{print $1}')
    docker stop reflector; docker rm reflector
    docker run -d --name reflector -e TARGET_SERVER=%0 -e TARGET_PORT=8000 -p 80:80 --restart=always xxaxxelxx/xx_reflector
    exit
fi

while true; do
# LOGGING #
    test -r $LOGFILE
    if [ $? -eq 0 ]; then
	cat $LOGFILE | tail -n 5000 > $LOGFILE.tmp && mv -f $LOGFILE.tmp $LOGFILE
    fi
#    ps aux | sort -nrk 3 | head -n 20 | grep -v ' 0.0 ' >> $LOGFILE
    test -r $PULSEFILE
    if [ $? -eq 0 ]; then
	LOAD=$(cat $PULSEFILE)
	if [ "x$STATUS" == "xACCEPT" ]; then
	    if [ $LOAD -ge $REFLECTLIMIT ]; then 
		REFCNT=$(($REFCNT+1))
		if [ $REFCNT -ge $REFLECT_AT ]; then
		    echo "X X X X X X X" >> $LOGFILE
		    echo "R E F L E C T" >> $LOGFILE
		    date >> $LOGFILE
		    echo "X X X X X X X" >> $LOGFILE

		    test -r /root/loadbalancer.addr
		    if [ $? -eq 0 ]; then
			LOADBALANCER=$(cat /root/loadbalancer.addr)
			docker stop reflector; docker rm reflector
			docker run -d --name reflector -e TARGET_SERVER=$LOADBALANCER -e TARGET_PORT=80 -p 80:80 --restart=always xxaxxelxx/xx_reflector && \
			iptables -t nat -I DOCKER 1 -p tcp --dport 8000 -j DNAT --to-destination $(iptables -n -L DOCKER | grep -w dpt:80 | awk '{print $5}'):80
			STATUS="REFLECT"
			ACCCNT=0
		    fi
		fi
	    else
		REFCNT=0
	    fi
	else
	    if [ $LOAD -lt $ACCEPTLIMIT ]; then 
		ACCCNT=$(($ACCCNT+1))
		if [ $ACCCNT -ge $ACCEPT_AT ]; then
		    echo "X X X X X X" >> $LOGFILE
		    echo "A C C E P T" >> $LOGFILE
		    date >> $LOGFILE
		    echo "X X X X X X" >> $LOGFILE

		    if [ $? -eq 0 ]; then
			iptables -t nat -D DOCKER $(iptables -t nat -L DOCKER --line-numbers | grep -w dpt:8000 | grep ':80$' | awk '{print $1}')
			docker stop reflector; docker rm reflector
			docker run -d --name reflector -e TARGET_SERVER=%0 -e TARGET_PORT=8000 -p 80:80 --restart=always xxaxxelxx/xx_reflector && \
			STATUS="ACCEPT"
			REFCNT=0
		    fi
		fi
	    else
		ACCCNT=0
	    fi
	    
	fi
    fi
sleep $SLEEP
done

exit
