#! /bin/bash


#We source the passwords
source ../../0.General/pass_file
env | grep pass

#------------------------------------Step 2 Installation Compute node------------------------------

apt-get install -y nova-compute sysfsutils

cp sources/nova.conf /etc/nova/nova.conf

chown nova.nova /etc/nova/nova.conf

read -p "Quelle est l'IP du ce serveur?: " compute_ip

sed -i "s/MY_IP/$compute_ip/g" /etc/nova/nova.conf
###No need anymore since the MY_IP flag will change it too
#sed -i "s/vncserver_proxyclient_address =/vncserver_proxyclient_address = $compute_ip/g" /etc/nova/nova.conf

sed -i "s/NOVA_PASS/${nova_user_pass}/g" /etc/nova/nova.conf

service nova-compute restart

rm -f /var/lib/nova/nova.sqlite


echo -e "\nCompute Node 100% installed\n"

echo -e "\nDO NOT FORGET TO DO THE VERIFICATION PROCESS ON THE CONTROLLER NODE!!\n"
