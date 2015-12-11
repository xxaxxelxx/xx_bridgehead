#!/bin/bash
test -r icecast.machines.list

WIDTH=60; HEIGHT=30; LHEIGHT=25
RES=$(dialog --clear --stdout --radiolist "Select your mode" $WIDTH $HEIGHT $LHEIGHT proxy mode aa player mode bb loadbalancer mode cc)
MODE="UNDEF"
RUNDIR="RUN"
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

test -d $RUNDIR || mkdir -p $RUNDIR 

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

function channelselect() {
	    OIFS="$IFS"; IFS=$'\n'; LIQA_LIST=($(docker run --rm xxaxxelxx/xx_liquidsoap | grep $1)); IFS="$OIFS"
	    DIALOG_LIST=""
	    for CITEM in "${LIQA_LIST[@]}"; do
		DIALOG_LIST="$DIALOG_LIST $CITEM :) x"
	    done
	    PRESEL="$(dialog --clear --stdout --checklist "Select: " $HEIGHT $WIDTH $LHEIGHT $DIALOG_LIST )"
	    for LIQITEM in $PRESEL; do
		DOCKER_NAME="liquidsoap_$LIQITEM"
		DOCKER_CMD="docker run -d --name $DOCKER_NAME --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $LIQITEM"
	    	exec $DOCKER_CMD && echo "$DOCKERCMD" > $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME 
		echo "docker run -d --name liquidsoap_$LIQITEM --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $LIQITEM"
	    done
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
    DOCKER_NAME="icecast_proxy" && DOCKER_CMD="docker run -d --name $DOCKER_NAME -p $IC_PORT:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast proxy"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
    else
	echo	 "Do it again."
	exit 1
    fi


elif [ $MODE = "LOADBALANCER" ]; then
    # UPDATE ADMIN PASSWORD
    UPDATE_ADMIN_PASS="$(dialog --stdout --inputbox "Update password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="-e UPDATEPASSWORD=$UPDATE_ADMIN_PASS"

    # RUN LOADBALANCER
    DOCKER_NAME="loadbalancer" && DOCKER_CMD="docker run -d --name $DOCKER_NAME -p 80:80 $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_loadbalancer"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME

    # CREATE VOLUMES
    docker create -v /customer --name customerdatavolume debian /bin/true
    docker create -v /depot --name depotdatavolume debian /bin/true

    # RUN SSHDEPOT
    DOCKER_NAME="sshdepot" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from depotdatavolume --volumes-from customerdatavolume -p 65522:22 --restart=always xxaxxelxx/xx_sshdepot"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME


    # RUN CONVERTER
    DOCKER_NAME="converter" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from sshdepot --restart=always xxaxxelxx/xx_converter"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME

    OIFS="$IFS"; IFS=$'\n'; A_CUSTOMERS=($(cat customer.list | grep -v -e '^#' | grep -v -e '^$' | awk '{print $1}' | sort -u )); IFS="$OIFS"
    # RUN LOGSPLITTER
    DOCKER_NAME="logsplitter" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from sshdepot --restart=always xxaxxelxx/xx_logsplitter ${A_CUSTOMERS[@]}"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME

    CUSTOMER_PASS_ADMIN="$(dialog --stdout --inputbox "Set customer areas admin password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="-e CUSTOMERPASSWORD_admin=$CUSTOMER_PASS_ADMIN"
    for CUSTOMER in ${A_CUSTOMERS[@]}; do
	CUSTOMER_PASS="$(dialog --stdout --inputbox "Set $CUSTOMER password please:" $HEIGHT $WIDTH)"
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e CUSTOMERPASSWORD_$CUSTOMER=$CUSTOMER_PASS"
    done
    # RUN CUSTOMERWEB
    DOCKER_NAME="customerweb" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from sshdepot $DOCKER_ENV_STRING -p 81:80 --restart=always xxaxxelxx/xx_customerweb  ${A_CUSTOMERS[@]}"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME

    # RUN RRDCOLLECTOR ADMIN
    DOCKER_NAME="rrdcollector_admin" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from customerweb --link loadbalancer:loadbalancer -e RRD_LOOP=300 --restart=always xxaxxelxx/xx_rrdcollect admin"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
    
    for CUSTOMER in ${A_CUSTOMERS[@]}; do
	# RUN RRDCOLLECTOR CUSTOMERS
        DOCKER_NAME="rrdcollector_$CUSTOMER" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from customerweb --link loadbalancer:loadbalancer -e RRD_LOOP=300 --restart=always xxaxxelxx/xx_rrdcollect $CUSTOMER"
        $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
    done

    # RUN RRDGRAPH ADMIN
    DOCKER_NAME="rrdgraph_admin" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from customerweb -e LOOP=300 -e GROUPMARKER=ch --restart=always xxaxxelxx/xx_rrdgraph admin"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME

    for CUSTOMER in ${A_CUSTOMERS[@]}; do
	# RUN RRDGRAPH CUSTOMERS
	DOCKER_NAME="rrdgraph_$CUSTOMER" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from customerweb -e LOOP=300 -e GROUPMARKER=ch --restart=always xxaxxelxx/xx_rrdgraph $CUSTOMER"
	$DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
    done
    for CUSTOMER in ${A_CUSTOMERS[@]}; do
	# RUN ACCOUNT CUSTOMERS
	CUSTOMER_PRICE="$(dialog --stdout --inputbox "Set ${CUSTOMER}'s price in Cent per MByte please:" $HEIGHT $WIDTH 0,00)"
	DOCKER_NAME="account_$CUSTOMER" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --volumes-from sshdepot --restart=always xxaxxelxx/xx_account $CUSTOMER $CUSTOMER_PRICE"
        $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
    done

elif [ $MODE = "PLAYER" ]; then
#    OIFS="$IFS"; IFS=$'\n'; A_LIST=($(cat icecast.machines.list | grep -v -e '^#' | grep -v -e '^$' | awk '{print $3$2}' | sort -u )); IFS="$OIFS"    
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
	DOCKER_NAME="icecast_player" && DOCKER_CMD="docker run -d --name $DOCKER_NAME -p 80:$IC_PORT $DOCKER_ENV_STRING -v /usr/share/icecast2/web -v /var/log/icecast2/ --restart=always xxaxxelxx/xx_icecast player"
	$DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
    else
	echo "Do it again."
	exit 1
    fi
    for LIQS in $PRESEL; do
	case $LIQS in
	    BBRSIMULCAST)
	    TRIGGER="bbradio"
	    DOCKER_NAME="liquidsoap_$TRIGGER" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER"
	    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
	    ;;
	    BBRCHANNELS)
	    TRIGGER="bbradio-ch"
	    channelselect $TRIGGER
	    ;;
	    TDYSIMULCAST)
	    TRIGGER="radioteddy"
	    DOCKER_NAME="liquidsoap_$TRIGGER" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER"
	    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
	    ;;
	    TDYCHANNELS)
	    TRIGGER="radioteddy-ch"
	    channelselect $TRIGGER
	    ;;
	    OWSIMULCAST)
	    TRIGGER="ostseewelle"
	    DOCKER_NAME="liquidsoap_$TRIGGER" && DOCKER_CMD="docker run -d --name $DOCKER_NAME --link icecast_player:icplayer --restart=always xxaxxelxx/xx_liquidsoap $TRIGGER"
	    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
	    ;;
	    OWCHANNELS)
	    TRIGGER="ostseewelle-ch"
	    channelselect $TRIGGER
	    ;;
	esac
    done
    LOADBALANCER_ADDR="$(dialog --stdout --inputbox "Loadbalancer address please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="-e LOADBALANCER_ADDR=$LOADBALANCER_ADDR"

    KEY_DECRYPT_PASS="$(dialog --stdout --inputbox "Key decrypt password:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING_DECRYPT="-e KEY_DECRYPT_PASS=$KEY_DECRYPT_PASS"

    DOCKER_NAME="sshsatellite" && DOCKER_CMD="docker run -d --name $DOCKER_NAME -v /tmp:/tmp --volumes-from icecast_player $DOCKER_ENV_STRING $DOCKER_ENV_STRING_DECRYPT -e LOOP_SEC=10 --link icecast_player:icplayer --restart=always xxaxxelxx/xx_sshsatellite"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME

    UPDATE_ADMIN_PASS="$(dialog --stdout --inputbox "Update admin password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e UPDATE_ADMIN_PASS=$UPDATE_ADMIN_PASS"
    BW_LIMIT="$(dialog --stdout --inputbox "Bandwidth limit in kbitps please:" $HEIGHT $WIDTH 0)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e BW_LIMIT=$BW_LIMIT"

    DOCKER_NAME="pulse" && DOCKER_CMD="docker run -d --name $DOCKER_NAME -v /proc/net/dev:/host/proc/net/dev:ro -v /proc/stat:/host/proc/stat:ro $DOCKER_ENV_STRING -e LOOP_SEC=5 --link icecast_player:icplayer --restart=always xxaxxelxx/xx_pulse"
    $DOCKER_CMD && echo "$DOCKER_CMD" >> $RUNDIR/$(date +%Y-%m-%d_%H%M%S).$DOCKER_NAME
fi

./icecast_trigger.sh &

exit
