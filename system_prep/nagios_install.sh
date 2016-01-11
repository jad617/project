#!/bin/bash


cd "$(dirname "$0")"

apt-get -y install nagios-nrpe-server nagios-plugins

cp sources/nrpe.cfg /etc/nagios/nrpe.cfg

echo -e "\n"
read -p "What is the ip of your Nagios server?: " nagios_ip

sed -i "s/NAGIOS_SERVER/$nagios_ip/g" /etc/nagios/nrpe.cfg

