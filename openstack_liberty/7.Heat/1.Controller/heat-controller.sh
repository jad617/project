#! /bin/bash

cd "$(dirname "$0")"

source ../../0.General/pass_file

source ../../../ceph_scripts/export_file

source ../../0.General/openstack_functions

source ../../0.General/ceph_openstack_functions
######---------------------------------Heat Database configuration----------------------------------------

#We run the MySQL function from ../../0.General/openstack_functions
f_mysql heat $heat_DBpass

#################Creating Heat users and roles in Openstack------------------------------------------
source /root/admin-openrc.sh

#Create the heat user
openstack user create --domain default --password ${heat_user_pass} heat

#Add the admin role to the heat user
openstack role add --project service --user heat admin

#Create the heat and heat-cfn service entities
openstack service create --name heat \
  --description "Orchestration" orchestration

openstack service create --name heat-cfn \
  --description "Orchestration"  cloudformation

#Create the Orchestration service API endpoints:

openstack endpoint create --region RegionOne \
  orchestration public http://controller:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  orchestration internal http://controller:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  orchestration admin http://controller:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  cloudformation public http://controller:8000/v1

openstack endpoint create --region RegionOne \
  cloudformation internal http://controller:8000/v1

openstack endpoint create --region RegionOne \
  cloudformation admin http://controller:8000/v1

#Create the heat domain that contains projects and users for stacks
openstack domain create --description "Stack projects and users" heat

#Create the heat_domain_admin user to manage projects and users in the heat domain:
openstack user create --domain heat --password ${heat_domain_pass} heat_domain_admin

#Add the admin role to the heat_domain_admin user in the heat domain to enable administrative stack management privileges by the heat_domain_admin user
openstack role add --domain heat --user heat_domain_admin admin

#Create the heat_stack_owner role
openstack role create heat_stack_owner

#Add the heat_stack_owner role to the demo project and user to enable stack management by the demo user:
openstack role add --project demo --user demo heat_stack_owner

#Create the heat_stack_user role
#To avoid conflicts, do not add this role to users with the heat_stack_owner role.
openstack role create heat_stack_user

#--------------------------------------------------Install and configure Heat---------------------------------

apt-get install heat-api heat-api-cfn heat-engine \
  python-heatclient

cp sources/heat.conf /etc/heat/heat.conf
chown heat.heat /etc/heat/heat.conf

sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/heat/heat.conf

sed -i "s/HEAT_PASS/${heat_user_pass}/g" /etc/heat/heat.conf
sed -i "s/HEAT_DBPASS/${heat_DBpass}/g" /etc/heat/heat.conf
sed -i "s/HEAT_DOMAIN_PASS/${heat_domain_pass}/g" /etc/heat/heat.conf

#Populate the Orchestration database:
su -s /bin/sh -c "heat-manage db_sync" heat

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

rm -f /var/lib/heat/heat.sqlite

#---------------------------------------------Verification----------------------------------------

read -p "Press any key to start the Heat verifiaction process" fake

source /root/admin-openrc.sh


heat service-list



















