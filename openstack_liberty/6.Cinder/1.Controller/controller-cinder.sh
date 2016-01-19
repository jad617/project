#! /bin/bash

cd "$(dirname "$0")"

source ../../0.General/pass_file

source ../../../ceph_scripts/export_file

source ../../0.General/openstack_functions

source ../../0.General/ceph_openstack_functions
######---------------------------------Glance Database configuration----------------------------------------

#We run the MySQL function from ../../0.General/openstack_functions
f_mysql cinder $cinder_DBpass

#################Creating Neutron users and roles in Openstack------------------------------------------
source /root/admin-openrc.sh


#Create a cinder user:
openstack user create --domain default --password ${cinder_user_pass} cinder

#Add the admin role to the cinder user:
openstack role add --project service --user cinder admin

#Create the cinder and cinderv2 service entities:
openstack service create --name cinder \
  --description "OpenStack Block Storage" volume

openstack service create --name cinderv2 \
  --description "OpenStack Block Storage" volumev2

#Create the Block Storage service API endpoints:
openstack endpoint create --region RegionOne \
  volume public http://controller:8776/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  volume internal http://controller:8776/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  volume admin http://controller:8776/v1/%\(tenant_id\)s

#cinderv2
openstack endpoint create --region RegionOne \
  volumev2 public http://controller:8776/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  volumev2 internal http://controller:8776/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  volumev2 admin http://controller:8776/v2/%\(tenant_id\)s

#-----------------------------------------------------------------------Cinder-API Installation------------------------------------------

apt-get install -y cinder-api cinder-scheduler python-cinderclient

cp sources/cinder.conf /etc/cinder/cinder.conf
chown cinder.cinder /etc/cinder/cinder.conf


sed -i "s/CINDER_DBPASS/$cinder_DBpass/g" /etc/cinder/cinder.conf
sed -i "s/RABBIT_PASS/$rabbit_pass/g" /etc/cinder/cinder.conf
sed -i "s/CINDER_PASS/$cinder_user_pass/g" /etc/cinder/cinder.conf

sed -i "s/MY_IP/$controller_ip/g" /etc/cinder/cinder.conf

su -s /bin/sh -c "cinder-manage db sync" cinder


service nova-api restart
service cinder-scheduler restart
service cinder-api restart

rm -f /var/lib/cinder/cinder.sqlite


#----------------------------------------------------------------------Cinder-Volume Installation----------------------------------------------

apt-get install -y cinder-volume python-mysqldb


service cinder-volume restart

rm -f /var/lib/cinder/cinder.sqlite

#-----------------------------------------------------------------------Ceph Storage Config------------------------------------------------

ceph auth get-or-create client.cinder | tee /etc/ceph/${cluster_name}.client.cinder.keyring
chown cinder:cinder /etc/ceph/${cluster_name}.client.cinder.keyring

#####TEST EXPERIMENTAL
ceph auth get-or-create client.nova | tee /etc/ceph/${cluster_name}.client.nova.keyring
chown nova:nova /etc/ceph/${cluster_name}.client.nova.keyring
######################

sed -i "s/CLUSTER_NAME/$cluster_name/g" /etc/cinder/cinder.conf 
sed -i "s/SECRET_UUID/$secret_uuid/g" /etc/cinder/cinder.conf 

service cinder-volume restart
#------------------------------------------------------------------------Verify Operations-----------------------------------------------------

source /root/admin-openrc.sh

cinder service-list
