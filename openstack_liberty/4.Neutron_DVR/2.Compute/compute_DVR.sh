#! /bin/bash

source ../../0.General/pass_file #for all the OpenStack Generated Passwords

source ../../../ceph_scripts/export_file #for all the Ceph Genertated Passwords

source ../../0.General/openstack_functions # for all the OpenStack Functions created

#--------------------------------Sysctl conf-----------------------------#
cp sources/sysctl.conf /etc/sysctl.conf
chown root.root. /etc/sysctl.conf
modprobe br_netfilter

sysctl -p

#------------------------------------------------------------------------#
apt-get install -y neutron-server neutron-plugin-openvswitch \
neutron-plugin-openvswitch-agent neutron-common \
neutron-l3-agent neutron-metadata-agent openvswitch-switch conntrack

#apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent

cp sources/neutron.conf /etc/neutron/neutron.conf
chown root.neutron /etc/neutron/neutron.conf

cp sources/ml2_conf.ini /etc/neutron/plugins/ml2/
chown root.neutron /etc/neutron/plugins/ml2/ml2_conf.ini

cp sources/l3_agent.ini /etc/neutron/l3_agent.ini
chown root.neutron /etc/neutron/l3_agent.ini

cp sources/metadata_agent.ini /etc/neutron/metadata_agent.ini
chown root.neutron /etc/neutron/metadata_agent.ini


sed -i "s/NEUTRON_PASS/${neutron_user_pass}/g" /etc/nova/nova.conf
sed -i "s/METADATA_SECRET/${metadata_pass}/g" /etc/nova/nova.conf

sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/${neutron_user_pass}/g" /etc/neutron/neutron.conf


read -p "What is the IP of your Tunnel Interface?: " tunnel_ip
sed -i "s/TUNNEL_IP/${tunnel_ip}/g" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "s/METADATA_SECRET/${metadata_pass}/g" /etc/neutron/metadata_agent.ini

service openvswitch-switch restart

service nova-compute restart
service openvswitch-switch restart
service neutron-l3-agent restart
service neutron-metadata-agent restart
service neutron-plugin-openvswitch-agent restart

echo -e "\n Compute networking setup is done. Run the Second Controller Script\n"
