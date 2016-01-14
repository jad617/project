#! /bin/bash

interface_file=/etc/network/interfaces

#To find the default GATEWAY there are two commands that gives the same result
# ip route show default | grep "default" | cut -d" " -f3
# or
# netstat -rn | grep ^0.0.0.0 | cut -d" " -f10

read -p "What should be the last octet of your IP address?: " last_addr


eth0_addr="$(ifconfig eth0 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)"

gateway_addr=$(ip route show default | grep "default" | cut -d" " -f3)

echo "
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

#External Interface
auto eth0
iface eth0 inet manual
up ifconfig $IFACE 0.0.0.0 up
up ip link set $IFACE promisc on
down ip link set $IFACE promisc off
down ifconfig $IFACE down

auto br-ex
iface br-ex inet static
        address $eth0_addr
        netmask 255.255.255.0
        gateway $gateway_addr

#Management Interface
auto eth1
iface eth1 inet static
        address         10.0.0.$last_addr
        netmask         255.255.255.0


#Tunnel Interface
auto eth1:tun
iface eth1:tun inet static
        address         10.0.1.$last_addr
        netmask         255.255.255.0

#VLAN Interface
auto eth1:vlan
iface eth1:vlan inet static
        address         10.10.10.$last_addr
        netmask         255.255.255.0

#up ifconfig $IFACE 0.0.0.1 up
#up ip link set $IFACE promisc on
#down ip link set $IFACE promisc off
#down ifconfig $IFACE down

auto br-vlan
iface br-vlan inet manual
" > $interface_file

#-----------------------------------------------------Setup Open vSwitch-------------------------#
apt-get install -y openvswitch-switch

#In order for Open vSwitch to view the new Interfaces we need to reload the network configs
service networking restart

#We now create the brigdes and link them to their interface

ovs-vsctl add-br br-int
ovs-vsctl add-br br-vlan
ovs-vsctl add-br br-tun
ovs-vsctl add-br br-ex

ovs-vsctl add-port br-ex eth0           #For external access
ovs-vsctl add-port br-vlan eth1:vlan	#For Vlan access


#We now restart the Open vSwitch service and reboot
service openvswitch-switch restart
reboot

