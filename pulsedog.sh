#!/bin/bash

SLEEP=60
ALERTED=1
EJECT_AT=5
MAXPULSEAGE=60
LIMIT=98
PULSEFILE=/tmp/pulse.cpuload
LOGFILE=/root/pulse.log

CNT=0
while true; do
# LOGGING #
    test -r $LOGFILE
    if [ $? -eq 0 ]; then
	cat $LOGFILE | tail -n 5000 > $LOGFILE.tmp && mv -f $LOGFILE.tmp $LOGFILE
    fi
    echo "# # # # # # #" >> $LOGFILE
    date >> $LOGFILE
    ps aux | sort -nrk 3 | head -n 20 | grep -v ' 0.0 ' >> $LOGFILE
# # # # # #
    test -r $PULSEFILE
    if [ $? -eq 0 ]; then
	PULSEAGE="$(($(date +%s) - $(date +%s -r "$PULSEFILE")))"
	LOAD=$(cat $PULSEFILE)
	if [ $LOAD -ge $LIMIT -o $PULSEAGE -gt $MAXPULSEAGE ]; then 
	    ALERTED=0
	    CNT=$(($CNT+1))
	    if [ $CNT -ge $EJECT_AT ]; then
		echo "X X X X X X" >> $LOGFILE
		echo "R E B O O T" >> $LOGFILE
		echo "X X X X X X" >> $LOGFILE
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
