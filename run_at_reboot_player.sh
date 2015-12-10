#!/bin/bash
./icecast_trigger.sh &
./iptables.block_clients_master_access_at_player.sh
./iptables.block_dos_at_player.sh
exit
