#! /bin/bash

cd "$(dirname "$0")"

source ../../0.General/pass_file

source ../../../ceph_scripts/export_file

source ../../0.General/openstack_functions

source ../../0.General/ceph_openstack_functions
######---------------------------------Glance Database configuration----------------------------------------

#We run the MySQL function from ../../0.General/openstack_functions
f_mysql neutron $neutron_DBpass

#################Creating Neutron users and roles in Openstack------------------------------------------
source /root/admin-openrc.sh

#Create the neutron user
openstack user create --domain default --password ${neutron_user_pass} neutron

#Add the admin role to the neutron user
openstack role add --project service --user neutron admin

#Create the neutron service entity:
openstack service create --name neutron \
  --description "OpenStack Networking" network

#Create the Networking service API endpoints:
openstack endpoint create --region RegionOne \
  network public http://controller:9696

openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696

#-------------------------------------------------Installing Neutron Packages---------------------------------------
#different from Liberty guide since they make us setup Linux Bridge instead of OpenVSwitch
apt-get install -y neutron-server neutron-plugin-openvswitch \
neutron-plugin-openvswitch-agent neutron-common neutron-dhcp-agent \
neutron-l3-agent neutron-metadata-agent openvswitch-switch

cp sources/neutron.conf /etc/neutron/neutron.conf
chown root.neutron /etc/neutron/neutron.conf

cp sources/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
chown root.neutron /etc/neutron/plugins/ml2/ml2_conf.ini

cp sources/metadata_agent.ini /etc/neutron/metadata_agent.ini
chown root.neutron /etc/neutron/metadata_agent.ini

cp sources/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
chown root.neutron /etc/neutron/dhcp_agent.ini

cp sources/l3_agent.ini /etc/neutron/l3_agent.ini
chown root.neutron /etc/neutron/l3_agent.ini

cp sources/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf
chown root.neutron /etc/neutron/dnsmasq-neutron.conf

#---------------------------------------------Sysctl config--------------------------------#
cp sources/sysctl.conf /etc/sysctl.conf
chown root.root /etc/sysctl.conf

#We load the kernel module
modprobe br_netfilter

#We reload the kernal configuration after the changes
sysctl -p

#-------------------------------------------------------------------------------------------#

sed -i "s/NEUTRON_DBPASS/${neutron_DBpass}/g" /etc/neutron/neutron.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/${neutron_user_pass}/g" /etc/neutron/neutron.conf
sed -i "s/NOVA_PASS/${nova_user_pass}/g" /etc/neutron/neutron.conf

sed -i "s/NEUTRON_PASS/${neutron_user_pass}/g" /etc/neutron/metadata_agent.ini
sed -i "s/METADATA_SECRET/${metadata_pass}/g" /etc/neutron/metadata_agent.ini

sed -i "s/METADATA_SECRET/${metadata_pass}/g" /etc/nova/nova.conf
#INsert SSH to send to compute

#ssh -t -p $node_port $node_user@$node_ip "sudo mv /tmp/"$cluster_name".conf $folder_path"







