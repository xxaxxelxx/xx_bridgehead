#!/bin/bash
test -r icecast.machines.list

WIDTH=60; HEIGHT=30; LHEIGHT=25
RES=$(dialog --clear --stdout --radiolist "Select your mode" $WIDTH $HEIGHT $LHEIGHT proxy mode aa player mode bb)
MODE="UNDEF"
case $RES in
proxy)
    MODE="PROXY"
;;
player)
    MODE="PLAYER"
;;
esac

function set_ip() {
    OIFS="$IFS"; IFS=$'\n'; A_IPLIST=($(cat icecast.machines.list | grep -v -e '^#' | grep -iw $2 | grep -iw $3 | grep -iw $4 | awk '{print $4}')); IFS="$OIFS"
    if [ ${#A_IPLIST[@]} -eq 0 ]; then
	return 1
    elif [ ${#A_IPLIST[@]} -eq 1 ]; then
	echo "${A_IPLIST[0]}"; return 0
    else
	DIALOG_LIST=""
	for CIP in "${A_IPLIST[@]}"; do
	    DIALOG_LIST="$DIALOG_LIST $CIP $CID x"
	done
	echo "$(dialog --clear --stdout --radiolist "$CID" $HEIGHT $WIDTH $LHEIGHT $DIALOG_LIST)"
	return 0
    fi
}

if [ $MODE = "PROXY" ]; then
    DOCKER_ENV_STRING=""

    # SIMULCAST_MASTER_SERVER_BBR
    CID="SIMULCAST_MASTER_SERVER_BBR"
    TYPE_A="simulcast";TYPE_B="master"; TYPE_C="bbr";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # SIMULCAST_MASTER_SERVER_TDY
    CID="SIMULCAST_MASTER_SERVER_TDY"
    TYPE_A="simulcast";TYPE_B="master"; TYPE_C="tdy";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # SIMULCAST_MASTER_SERVER_OW
    CID="SIMULCAST_MASTER_SERVER_OW"
    TYPE_A="simulcast";TYPE_B="master"; TYPE_C="ow";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # CHANNEL_MASTER_SERVER_BBR
    CID="CHANNEL_MASTER_SERVER_BBR"
    TYPE_A="channels";TYPE_B="master"; TYPE_C="bbr";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # CHANNEL_MASTER_SERVER_TDY
    CID="CHANNEL_MASTER_SERVER_TDY"
    TYPE_A="channels";TYPE_B="master"; TYPE_C="tdy";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # CHANNEL_MASTER_SERVER_OW
    CID="CHANNEL_MASTER_SERVER_OW"
    TYPE_A="channels";TYPE_B="master"; TYPE_C="ow";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # MASTER SERVER PORT
    MASTER_SERVER_PORT="$(dialog --stdout --inputbox "Master Server port please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e MASTER_SERVER_PORT=$MASTER_SERVER_PORT"

    # ICECAST PORT
    IC_PORT="$(dialog --stdout --inputbox "Icecast port please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_PORT=$IC_PORT"

    # ICECAST ADMIN PASSWORD
    IC_ADMIN_PASS="$(dialog --stdout --inputbox "Icecast admin password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_ADMIN_PASS=$IC_ADMIN_PASS"

    dialog --yesno "docker run -d --name icecast_proxy -p $IC_PORT:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast proxy"  $HEIGHT $WIDTH
    if [ $? -eq 0 ]; then
	docker run -d --name icecast_proxy -p $IC_PORT:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast proxy	
    else
	echo "Do it again."
	exit 1
    fi

elif [ $MODE = "PLAYER" ]; then
    DOCKER_ENV_STRING=""

    # SIMULCAST_PROXY_SERVER_BBR
    CID="SIMULCAST_PROXY_SERVER_BBR"
    TYPE_A="simulcast";TYPE_B="proxy"; TYPE_C="bbr";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # SIMULCAST_PROXY_SERVER_TDY
    CID="SIMULCAST_PROXY_SERVER_TDY"
    TYPE_A="simulcast";TYPE_B="proxy"; TYPE_C="tdy";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # CHANNEL_PROXY_SERVER_BBR
    CID="CHANNEL_PROXY_SERVER_BBR"
    TYPE_A="channels";TYPE_B="proxy"; TYPE_C="bbr";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # CHANNEL_PROXY_SERVER_TDY
    CID="CHANNEL_PROXY_SERVER_TDY"
    TYPE_A="channels";TYPE_B="proxy"; TYPE_C="tdy";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # CHANNEL_PROXY_SERVER_OW
    CID="CHANNEL_PROXY_SERVER_OW"
    TYPE_A="channels";TYPE_B="proxy"; TYPE_C="ow";
    CRESULT="$(set_ip $CID $TYPE_A $TYPE_B $TYPE_C)"
    if [ $? -eq 0 ]; then
	DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e $CID=$CRESULT"
    fi

    # PROXY SERVER PORT
    PROXY_SERVER_PORT="$(dialog --stdout --inputbox "Proxy Server port please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e PROXY_SERVER_PORT=$PROXY_SERVER_PORT"

    # ICECAST PORT
    IC_PORT="$(dialog --stdout --inputbox "Icecast port please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_PORT=$IC_PORT"

    # ICECAST ADMIN PASSWORD
    IC_ADMIN_PASS="$(dialog --stdout --inputbox "Icecast admin password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_ADMIN_PASS=$IC_ADMIN_PASS"

    # ICECAST SOURCE PASSWORD
    IC_SOURCE_PASS="$(dialog --stdout --inputbox "Icecast source password please:" $HEIGHT $WIDTH)"
    DOCKER_ENV_STRING="$DOCKER_ENV_STRING -e IC_SOURCE_PASS=$IC_SOURCE_PASS"

    dialog --yesno "docker run -d --name icecast_player -p 80:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast player"  $HEIGHT $WIDTH
    if [ $? -eq 0 ]; then
	docker run -d --name icecast_player -p $IC_PORT:$IC_PORT $DOCKER_ENV_STRING --restart=always xxaxxelxx/xx_icecast player
    else
	echo "Do it again."
	exit 1
    fi
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
