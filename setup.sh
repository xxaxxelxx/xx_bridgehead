#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Usage: $(basename $0) proxy|player hostname"
    exit
fi

RELEASE="jessie"
MYHOSTNAME=$2

function f_basics() {
    test -d ~/.ssh
    if [ $? -ne 0 ]; then
	mkdir ~/.ssh
	chmod 700 ~/.ssh
    fi
    test -r authorized_keys2 
    if [ $? -eq 0 ]; then
	cat authorized_keys2 >> ~/.ssh/authorized_keys2 
	chmod 644 ~/.ssh/authorized_keys2
    fi
    cat /etc/apt/sources.list | grep $RELEASE-backports > /dev/null
    if [ $? -ne 0 ]; then
	echo "deb http://http.debian.net/debian $RELEASE-backports main" >> /etc/apt/sources.list
    fi
    apt-get -qq -y update
    apt-get -qq -y dist-upgrade
    apt-get -qq -y install rsync rdate mc telnet 
    apt-get -qq -y install docker.io
    echo "root:$(date | md5sum | awk '{print $1}')" | chpasswd

    if [ -n $MYHOSTNAME]; then
	echo "$MYHOSTNAME" >> /etc/hostname
    fi
}

function f_proxy() {
    test -r set.iptables.sh.proxy
    if [ $? -eq 0 ]; then
	cp -f set.iptables.sh.proxy /etc/network/if-up.d/iptables
	cp -f iptables.basic.rules /etc/
	cp -f iptables.addresses.players /etc/
	cp -f iptables.addresses.masters /etc/
	chmod 755 /etc/network/if-up.d/iptables
	exec /etc/network/if-up.d/iptables
    fi
}

function f_player() {
    test -r set.iptables.sh.player
    if [ $? -eq 0 ]; then
	cp -f set.iptables.sh.player /etc/network/if-up.d/iptables
	chmod 755 /etc/network/if-up.d/iptables
	exec /etc/network/if-up.d/iptables
    fi
}

case $1 in
[pP][rR][oO][xX][yY])
    f_basics
    f_proxy
;;
[pP][lL][aA][yY][eE][rR])
    f_basics
    f_player
;;
*)
    echo "Usage: $(basename $0) proxy|player"
    exit
;;
esac




exit