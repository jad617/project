#! /bin/bash


#We source the passwords
source ../../0.General/pass_file

source ../../0.General/ceph_openstack_functions

#------------------------------------Step 2 Installation Compute node------------------------------

apt-get install -y nova-compute sysfsutils

cp sources/nova.conf /etc/nova/nova.conf

chown nova.nova /etc/nova/nova.conf

read -p "What is the IP of your server?: " compute_ip

sed -i "s/MY_IP/$compute_ip/g" /etc/nova/nova.conf

sed -i "s/NOVA_PASS/${nova_user_pass}/g" /etc/nova/nova.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/nova/nova.conf

service nova-compute restart

rm -f /var/lib/nova/nova.sqlite


echo -e "\nCompute Node 100% installed\n"

echo -e "\nDO NOT FORGET TO DO THE VERIFICATION PROCESS ON THE CONTROLLER NODE!!\n"
