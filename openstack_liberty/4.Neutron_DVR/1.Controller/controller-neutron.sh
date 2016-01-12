#! /bin/bash

cd "$(dirname "$0")"

source ../../0.General/pass_file

source ../../../ceph_scripts/export_file

source ../../0.General/openstack_functions

source ../../0.General/ceph_openstack_functions
######---------------------------------Glance Database configuration----------------------------------------

####We generate the Glance Database Password

neutron_pass="$(openssl rand -hex 10)"

#We run the MySQL function from ../../0.General/openstack_functions
f_mysql neutron $neutron_pass

#################Creating Neutron users and roles in Openstack------------------------------------------

source /root/admin-openrc.sh

neutron_user_pass="$(openssl rand -hex 10)"

echo -e "#OpenStack Glance user pass:\nexport glance_user_pass=${neutron_user_pass} \n" >> ../../0.General/pass_file

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




















