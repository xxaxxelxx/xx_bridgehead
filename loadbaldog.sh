#!/bin/bash

SLEEP=10
LBFILE=LOADBALANCER_ADDR
LOGFILE=/root/loadbalancer.log

while true; do
# LOGGING #
    test -r $LOGFILE
    if [ $? -eq 0 ]; then
	cat $LOGFILE | tail -n 5000 > $LOGFILE.tmp && mv -f $LOGFILE.tmp $LOGFILE
    fi

    test -r $LBFILE
    if [ $? -eq 0 ]; then
	LB_OLD=$LB_CUR
	LB_CUR="$(cat LOADBALANCER_ADDR | grep -v '^#' | grep -v '^$' | grep -v '^\ *$' | awk '{print $1}')"
	if [ "x$LB_OLD" != "x" -a "x$LB_CUR" != "x" -a "x$LB_CUR" != "x$LB_OLD" ]; then 
	    ./docker.restart.sh pulse sshsat
    		echo "X X X X X X" >> $LOGFILE
		echo "LB CHANGED" >> $LOGFILE
		echo "$LB_OLD -> $LB_CUR" >> $LOGFILE
		date >> $LOGFILE
		echo "X X X X X X" >> $LOGFILE
	fi
    fi
sleep $SLEEP
done

exit
