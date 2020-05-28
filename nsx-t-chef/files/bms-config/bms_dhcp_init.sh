#!/bin/bash
#
# Copyright (C) 2018 VMware, Inc.  All rights reserved.
# SPDX-License-Identifier: BSD-2-Clause
#
# nsx-baremetal-server
#
# chkconfig: 2345 08 92
# description:

#
### BEGIN INIT INFO
# Provides:          nsx-baremetal-server
# Required-Start:
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: nsx-baremetal-server
### END INIT INFO


nsx_log() {
    echo "${1}"
    logger -p daemon.info -t NSX-BMS "${1}"
}

get_os_type() {
    host_os=$(lsb_release -si)
    nsx_log "host_os: $host_os"
}

isSUSE() {
    if [ "$host_os" == "SUSE" ]; then
        return 0
    fi
    return 1
}

start() {
    nsx_log "nsx-baremetal start"
    ip link add {{ app_intf_name }} type veth peer name {{ app_intf_name }}-peer
    ip link set dev {{ app_intf_name }} up
    ip link set dev {{ app_intf_name }} address {{ mac_address }}
    ip link set dev {{ app_intf_name }}-peer up
    ovs-vsctl --timeout=5 -- --if-exists del-port {{ app_intf_name }}-peer -- add-port {{ int_br_name }} {{ app_intf_name }}-peer \
    -- set Interface {{ app_intf_name }}-peer external-ids:attached-mac={{ mac_address }} \
    external-ids:iface-id={{ vif_id }} external-ids:iface-status=active
    if isSUSE; then
        ifup {{ app_intf_name }}
    else
        dhclient -nw -pf /var/run/dhclient-{{ app_intf_name }}.pid {{ app_intf_name }}
    fi
    routing_rules='{{ routing_rules }}'
    if [ "x$routing_rules" != "x" ]; then
        echo ${routing_rules} | awk '{len=split($0,a,",");for(i=1;i<=len;i++) system("route add "a[i]" dev {{ app_intf_name }}")}'
    fi
}

case "${1}" in
   "start")
      start
   ;;
   *)
      exit 1
   ;;
esac
