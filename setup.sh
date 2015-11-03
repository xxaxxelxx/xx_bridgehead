#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Usage: $(basename $0) proxy|player|loadbalancer hostname"
    exit
fi

RELEASE="jessie"

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
    apt-get -qq -y install rsync rdate mc telnet dialog 
    echo "root:$(date | md5sum | awk '{print $1}')" | chpasswd
    test -n $2 && echo "$2" > /etc/hostname
}

function f_proxy() {
    test -r set.iptables.sh.proxy
    if [ $? -eq 0 ]; then
	cp -f iptables.basic.rules /etc/
	cp -f iptables.addresses.players /etc/
	cp -f iptables.addresses.masters /etc/
	test ! -r /etc/network/if-up.d/iptables
	if [ $? -eq 0 ]; then
	    cp -f set.iptables.sh.proxy /etc/network/if-up.d/iptables
	    chmod 755 /etc/network/if-up.d/iptables
	    `/etc/network/if-up.d/iptables`
	else
	    cp -f set.iptables.sh.proxy /etc/network/if-up.d/iptables
	    chmod 755 /etc/network/if-up.d/iptables
	fi
    fi
}

function f_player() {
    test -r set.iptables.sh.player
    if [ $? -eq 0 ]; then
	cp -f iptables.basic.rules /etc/
	cp -f iptables.addresses.masters /etc/
	test ! -r /etc/network/if-up.d/iptables
	if [ $? -eq 0 ]; then
	    cp -f set.iptables.sh.player /etc/network/if-up.d/iptables
	    chmod 755 /etc/network/if-up.d/iptables
	    `/etc/network/if-up.d/iptables`
	else
	    cp -f set.iptables.sh.player /etc/network/if-up.d/iptables
	    chmod 755 /etc/network/if-up.d/iptables
	fi
    fi
}

function f_loadbalancer() {
    test -r set.iptables.sh.loadbalancer
    if [ $? -eq 0 ]; then
	cp -f iptables.basic.rules /etc/
	cp -f iptables.addresses.masters /etc/
	test ! -r /etc/network/if-up.d/iptables
	if [ $? -eq 0 ]; then
	    cp -f set.iptables.sh.loadbalancer /etc/network/if-up.d/iptables
	    chmod 755 /etc/network/if-up.d/iptables
	    `/etc/network/if-up.d/iptables`
	else
	    cp -f set.iptables.sh.loadbalancer /etc/network/if-up.d/iptables
	    chmod 755 /etc/network/if-up.d/iptables
	fi
    fi
}

case $1 in
[pP][rR][oO][xX][yY])
    f_basics $1 $2
    f_proxy
;;
[pP][lL][aA][yY][eE][rR])
    f_basics $1 $2
    f_player
;;
*)
    echo "Usage: $(basename $0) proxy|player|loadbalancer hostname"
    exit
;;
esac

apt-get -qq -y install docker.io

exit
