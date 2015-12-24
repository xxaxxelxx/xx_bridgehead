#!/bin/bash

SLEEP=60
ALERTED=1
EJECT_AT=10
LIMIT=95

CNT=0

STATFILE=/tmp/watchdog.info

echo "$(date) | Started." > $STATFILE

while true; do
    ps waux | grep icecast_player > /dev/null
    if [ $? -eq 0 ]; then
	IDLE=$(echo "scale=0; ($(grep "cpu " /proc/stat | awk -F ' ' '{total = $2 + $3 + $4 + $5} END {print $5*100/total}')/3)*3" | bc) #"
	if [ $IDLE -gt $LIMIT ]; then 
	    ALERTED=0
	    echo "$(date) | Alert: $IDLE idle. ${CNT}#${EJECT_AT}" > $STATFILE
	    CNT=$(($CNT+1))
	    if [ $CNT -ge $EJECT_AT ]; then
		echo "$(date) | EJECT." > $STATFILE
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
