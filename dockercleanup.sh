#!/bin/bash
docker stop $(docker ps -q) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null
ps waux | grep icecast_trigger.sh | grep -v grep | awk '{print $2}' | xargs kill -9 
exit
