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
