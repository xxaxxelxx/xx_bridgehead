#!/bin/bash
docker rmi $(docker images -q) 2>/dev/null
exit
