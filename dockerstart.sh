#!/bin/bash
test -r icecast.machines.list

WIDTH=60; HEIGHT=30; LHEIGHT=25
RES=$(dialog --clear --stdout --radiolist "Select your mode" $WIDTH $HEIGHT $LHEIGHT proxy mode aa player mode bb loadbalancer mode cc)
MODE="UNDEF"
case $RES in
proxy)
    MODE="PROXY"
;;
player)
    MODE="PLAYER"
;;
loadbalancer)
    MODE="LOADBALANCER"
;;
esac

function set_ip() {
    OIFS="$IFS"; IFS=$'\n'; A_IPLIST=($(cat icecast.machines.list | grep -v -e '^#' | grep -v -e '^$' | grep -iw $2 | grep -iw $3 | grep -iw $4 | awk '{print $4}')); IFS="$OIFS"
    if [ ${#A_IPLIST[@]} -eq 0 ]; then
	return 1
    elif [ ${#A_IPLIST[@]} -eq 1 ]; then
	echo "${A_IPLIST[0]}"; return 0
    else
	DIALOG_LIST=""
	for CIP in "${A_IPLIST[@]}"; do
	    DIALOG_LIST="$DIALOG_LIST $CIP $(cat icecast.machines.list | grep $CIP | awk '{print $5}' | sort -u) x"
	done
	echo "$(dialog --clear --stdout --radiolist "$CID" $HEIGHT $WIDTH $LHEIGHT $DIALOG_LIST)"
	return 0
    fi
}

function selector() {
	cat icecast.machines.list | awk '{print $1OFS$2OFS$3}' | sort -u | grep -wi "$1" | grep -v grep | grep -ve '^#' | grep -ve '^$' | tr [:lower:] [:upper:]
}

if [ $MODE = "PROXY" ]; then
    DOCKER_ENV_STRING=$(selector master | {
		while read LINE; do
	    L_ARRAY=($LINE)
	    CID="${L_ARRAY[1]}_${L_ARRAY[0]}_SERVER_${L_ARRAY[2]}"
    	    TYPE_A="${L_ARRAY[1]}";TYPE_B="${L_ARRAY[0]}"; TYPE_C="${L_ARRAY[2]}";
	    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
	    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
	done
	echo "$DOCKER_ENV_STRING"
    })

    # ICECAST PORT
    IC_PORT=8000
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_PORT=$IC_PORT"

    # MASTER SERVER PORT
    MASTER_SERVER_PORT="$(dialog --stdout --inputbox "Master Server port please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e MASTER_SERVER_PORT=$MASTER_SERVER_PORT"

    # ICECAST ADMIN PASSWORD
    IC_ADMIN_PASS="$(dialog --stdout --inputbox "Icecast admin password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_ADMIN_PASS=$IC_ADMIN_PASS"

    dialog --yesno "docker run -d --name icecast_proxy -p $IC_PORT:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast proxy"  $HEIGHT $WIDTH
    if [ $? -eq 0 ]; then
	docker run -d --name icecast_proxy -p $IC_PORT:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast proxy	
    else
	echo	 "Do it again."
	exit 1
    fi
elif [ $MODE = "LOADBALANCER" ]; then
    # UPDATE ADMIN PASSWORD
    UPDATE_ADMIN_PASS="$(dialog --stdout --inputbox "Update password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="-e UPDATEPASSWORD=$UPDATE_ADMIN_PASS"
    docker run -d --name loadbalancer -p 80:80 $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_loadbalancer
    docker run -d --name icecastwebdirectorymaster -p 65522:22 --restart=always xxaxxelxx/xx_icecastwebdirectory_master
elif [ $MODE = "PLAYER" ]; then
    
    OIFS="$IFS"; IFS=$'\n'; A_LIST=($(cat icecast.machines.list | grep -v -e '^#' | grep -v -e '^$' | awk '{print $3$2}' | sort -u )); IFS="$OIFS"
    DIALOG_LIST=""
    for CITEM in "${A_LIST[@]}"; do
	DIALOG_LIST="$DIALOG_LIST $CITEM :) x"
    done
    PRESEL="$(dialog --clear --stdout --checklist "WANNA PLAY?" $HEIGHT $WIDTH $LHEIGHT $DIALOG_LIST | tr [:lower:] [:upper:])"
    DOCKER_ENV_STRING=$(selector proxy | {
	while read LINE; do
	    L_ARRAY=($LINE)
	    CID="${L_ARRAY[1]}_${L_ARRAY[0]}_SERVER_${L_ARRAY[2]}"
	    echo $PRESEL | grep ${L_ARRAY[2]}${L_ARRAY[1]} > /dev/null || continue
    	    TYPE_A="${L_ARRAY[1]}";TYPE_B="${L_ARRAY[0]}"; TYPE_C="${L_ARRAY[2]}";
	    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
	    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
	done
	echo "$DOCKER_ENV_STRING"
    })

    # ICECAST PORT
    IC_PORT=8000
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_PORT=$IC_PORT"

    # PROXY SERVER PORT
    PROXY_SERVER_PORT="$(dialog --stdout --inputbox "Proxy Server port please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e PROXY_SERVER_PORT=$PROXY_SERVER_PORT"

    # ICECAST ADMIN PASSWORD
    IC_ADMIN_PASS="$(dialog --stdout --inputbox "Icecast admin password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_ADMIN_PASS=$IC_ADMIN_PASS"

    # ICECAST SOURCE PASSWORD
    IC_SOURCE_PASS="$(dialog --stdout --inputbox "Icecast source password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_SOURCE_PASS=$IC_SOURCE_PASS"

    dialog --yesno "docker run -d --name icecast_player -p 80:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast player"  $HEIGHT $WIDTH
    if [ $? -eq 0 ]; then
#	echo "ic player dockered"
	docker run -d --name icecast_player -p 80:$IC_PORT $DOCKER_ENV_STRING -v /usr/share/icecast2/web --restart=always xxaxxelxx/xx_icecast player
    else
	echo "Do it again."
	exit 1
    fi
    
    for LIQS in $PRESEL; do
#    echo "x $LIQS"
	case $LIQS in
	    BBRSIMULCAST)
	    TRIGGER="bbradio"
#	    echo "$TRIGGER liq dockered"
	    	docker run -d --name liquidsoap_$TRIGGER --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER
	    ;;
	    BBRCHANNELS)
	    TRIGGER="bbradio-ch"
#	    echo "$TRIGGER liq dockered"
	    	docker run -d --name liquidsoap_$TRIGGER --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER
	    ;;
	    TDYSIMULCAST)
	    TRIGGER="radioteddy"
#	    echo "$TRIGGER liq dockered"
	    	docker run -d --name liquidsoap_$TRIGGER --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER
	    ;;
	    TDYCHANNELS)
	    TRIGGER="radioteddy-ch"
#	    echo "$TRIGGER liq dockered"
	    	docker run -d --name liquidsoap_$TRIGGER --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER
	    ;;
	    OWSIMULCAST)
	    TRIGGER="ostseewelle"
#	    echo "$TRIGGER liq dockered"
	    	docker run -d --name liquidsoap_$TRIGGER --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER
	    ;;
	    OWCHANNELS)
	    TRIGGER="ostseewelle-ch"
#	    echo "$TRIGGER liq dockered"
	    	docker run -d --name liquidsoap_$TRIGGER --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER
	    ;;
	esac
    done
    LOADBALANCER_ADDR="$(dialog --stdout --inputbox "Loadbalancer address please:" $HEIGHT $WIDTH 78.46.202.79)"
    DOCKER_ENV_STRING="-e LOADBALANCER_ADDR=$LOADBALANCER_ADDR"

    docker run -d --name icecastwebdirectoryslave --volumes-from icecast_player $DOCKER_ENV_STRING -e LOOP_SEC=60 --link icecast_player:icplayer --restart=always xxaxxelxx/xx_icecastwebdirectory_slave

    UPDATE_ADMIN_PASS="$(dialog --stdout --inputbox "Update admin password please:" $HEIGHT $WIDTH zuppizuppi)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e UPDATE_ADMIN_PASS=$UPDATE_ADMIN_PASS"
    BW_LIMIT="$(dialog --stdout --inputbox "Bandwidth limit in kbitps please:" $HEIGHT $WIDTH 0)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e BW_LIMIT=$BW_LIMIT"

    docker run -d --name pulse -v /proc/net/dev:/host/proc/net/dev:ro -v /proc/stat:/host/proc/stat:ro $DOCKER_ENV_STRING -e LOOP_SEC=5 --link icecast_player:icplayer --restart=always xxaxxelxx/xx_pulse
fi

exit

# PLAY
#docker run -d --name icecast_proxy_test -p 80:8000 -e IC_PORT=8000 -e PROXY_SERVER_PORT=8000 \
#    -e SIMULCAST_PROXY_SERVER_BBR=141.16.141.2 -e CHANNEL_PROXY_SERVER_BBR=62.225.48.243 \
#    -e SIMULCAST_PROXY_SERVER_TDY=141.16.141.2 -e CHANNEL_PROXY_SERVER_TDY=62.225.48.243 \
#    -e SIMULCAST_PROXY_SERVER_OW=141.16.141.2 -e CHANNEL_PROXY_SERVER_OW=62.225.48.243 \
#    -e IC_ADMIN_PASS=12345678 \
#    -e IC_SOURCE_PASS=12345678 \    
#    --restart=always \
#    xxaxxelxx/xx_icecast proxy

# PROX
#docker run -d --name icecast_proxy_test -p 8000:8000 -e IC_PORT=8000 -e MASTER_SERVER_PORT=80 \
#    -e SIMULCAST_MASTER_SERVER_BBR=141.16.141.2 -e CHANNEL_MASTER_SERVER_BBR=62.225.48.243 \
#    -e SIMULCAST_MASTER_SERVER_TDY=141.16.141.2 -e CHANNEL_MASTER_SERVER_TDY=62.225.48.243 \
#    -e SIMULCAST_MASTER_SERVER_OW=141.16.141.2 -e CHANNEL_MASTER_SERVER_OW=62.225.48.243 \
#    -e IC_ADMIN_PASS=12345678 \
#    --restart=always \
#    xxaxxelxx/xx_icecast proxy
