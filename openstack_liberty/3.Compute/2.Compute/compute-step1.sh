#! /bin/bash

#------------------------------Configuaration of the /etc/hosts file---------------
#bash ../../0.General/hosts.sh
#Was moved to /root/project/system_prep
#------------------------------Step-1 Installation on Compute srv----------------------------------
bash ../../0.General/node_packages
#apt-get update
#apt-get install ntp -y

#sed -i "s/server/#server/g" /etc/ntp.conf
#echo "server controller iburst" >> /etc/ntp.conf

#service ntp restart

#apt-get install ubuntu-cloud-keyring -y
#echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
# "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

#apt-get update && apt-get dist-upgrade -y
#---------------------------------Install Nagios--------------
#bash ../../0.General/nagios_install
#Was moved to /root/project/system_prep

reboot
