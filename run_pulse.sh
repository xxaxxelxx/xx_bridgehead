#!/bin/bash

docker run -it --rm --name pulse -e ADMIN_PASS=zuppizuppi -e LOOP_SEC=3 -e LOADBALANCER_ADDR=78.46.202.79 -e MOUNTPOINT_LIST=dummy.mpg -e BW_LIMIT=0 -v /proc/net/dev:/host/proc/net/dev:ro -v /proc/stat:/host/proc/stat:ro xxaxxelxx/xx_pulse

exit