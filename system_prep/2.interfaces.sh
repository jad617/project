#! /bin/bash

#----------------------------------------------Adding some aliases for productivity reasons-----------------------#

echo "alias boss='sudo su -'" >> /etc/bash.bashrc

#-----------------------------------------------Adding nameservers for resolvconf----------------------------------#

echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/base
resolvconf -u


#-----------------------------------------------Configuring the Interfaces-----------------------------------------#
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
apt-get update 
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

#We will disable the sleep options in /etc/init/failsafe.conf because, with our network configuration, it will give a false positive and hang for more than 2 minutes
sed -i "s/sleep/#sleep/g" /etc/init/failsafe.conf

#Disable SSH timeout
echo "ClientAliveInterval 30
ClientAliveCountMax 99999
" >> /etc/ssh/sshd_config

#We now restart the Open vSwitch service and reboot
service openvswitch-switch restart
reboot


#####IMPORTANT FOR LATER-------------------------
#2. Change the GRUB config file to disable the name change:
#vi /etc/default/grub

#Find the GRUB_CMDLINE_LINUX_DEFAULT entry and add the following 2 items between the quotes in this file. 
#"net.ifnames=1 biosdevname=0"

#This is exactly how my line looked, including the quotes:
#GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=1 biosdevname=0"

#3. Run update-grub to update your grub configuration, but do not reboot yet. 
#update-grub

#4. Edit your /etc/network/interfaces and change the em1 entries to eth0 and em2 to eth1 and so on:
#vi /etc/network/interfaces
#Before edit:

# The primary network interface
#auto em1
#iface em1 inet dhcp

#After Edit:

# The primary network interface
#auto eth0
#iface eth0 inet dhcp


#5. Change any other software that is interface specific from em1 to eth0 before you reboot. 
#6. Reboot. 



