#!/bin/bash
while true; do
    test -f /tmp/icecast.hup.sem && pkill -HUP icecast2 && rm -f /tmp/icecast.hup.sem
    sleep 3
done
exit