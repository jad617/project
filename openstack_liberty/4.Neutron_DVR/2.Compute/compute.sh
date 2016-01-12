#! /bin/bash

source ../../0.General/pass_file #for all the OpenStack Generated Passwords

source ../../../ceph_scripts/export_file #for all the Ceph Genertated Passwords

source ../../0.General/openstack_functions # for all the OpenStack Functions created

#----------------------------------------------------------------------------------------#

modprobe br_netfilter

sysctl -p

#apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent

cp sources/neutron.conf /etc/neutron/neutron.conf

chown root.neutron /etc/neutron/neutron.conf

cp sources/ml2_conf.ini /etc/neutron/plugins/ml2/
chown root.neutron /etc/neutron/plugins/ml2/ml2_conf.ini


sed -i "s/NEUTRON_PASS/${neutron_user_pass}/g" /etc/nova/nova.conf
sed -i "s/METADATA_SECRET/${metadata_pass}/g" /etc/nova/nova.conf















service openvswitch-switch restart

service nova-compute restart

service neutron-plugin-openvswitch-agent restart

echo -e "\n Compute networking setup is done\n"
