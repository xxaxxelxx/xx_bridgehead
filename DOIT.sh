#!/bin/bash
#SRCFILE="LOADBALANCER_ADDR"
#TARFILE="/etc/$SRCFILE"
#test -r $SRCFILE
#if [ $? -eq 0 ]; then
#    cp -f "$SRCFILE" "$TARFILE" && \
#    echo "File $SRCFILE exists. File copied to $TARFILE."
#fi

SRCFILE="rc.local.player"
TARFILE="/etc/rc.local"
test -r $SRCFILE
if [ $? -eq 0 ]; then
    cp -f "$SRCFILE" "$TARFILE" && \
    echo "File $SRCFILE exists. File copied to $TARFILE."
fi

pkill loadbaldog.sh
./loadbaldog.sh &

test -d /var/log/icecast2 || mkdir -p /var/log/icecast2 
test -d /var/log/icecast2 && chmod -R 777 /var/log/icecast2

exit
