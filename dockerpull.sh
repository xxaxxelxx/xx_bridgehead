#!/bin/bash
docker images | grep -v REPOS | awk '{print $1}' | while read LINE; do docker pull $LINE 2>/dev/null; done
exit
