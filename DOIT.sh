#!/bin/bash
SRCFILE="iptables.basic.rules"
TARFILE="/etc/$SRCFILE"
test -r $SRCFILE
if [ $? -eq 0 ]; then
    cp -f "$SRCFILE" "$TARFILE" && \
    echo "File $SRCFILE exists. File copied to $TARFILE."
fi

SRCFILE="rc.local.player"
TARFILE="/etc/rc.local"
test -r $SRCFILE
if [ $? -eq 0 ]; then
    cp -f "$SRCFILE" "$TARFILE" && \
    echo "File $SRCFILE exists. File copied to $TARFILE."
fi

exit
