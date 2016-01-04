#!/bin/bash

SLEEP=60
ALERTED=1
EJECT_AT=5
LIMIT=95
PULSEFILE=/tmp/pulse.cpuload

CNT=0
while true; do
    test -r $PULSEFILE
    if [ $? -eq 0 ]; then
echo $(($(date +%s) - $(date +%s -r "$filename")))
	LOAD=$(cat $PULSEFILE)
	if [ $LOAD -ge $LIMIT ]; then 
	    ALERTED=0
	    CNT=$(($CNT+1))
	    if [ $CNT -ge $EJECT_AT ]; then
		reboot
		exit
	    fi
	else
	    ALERTED=1
	    CNT=0
	fi
    fi
sleep $SLEEP
done

exit
