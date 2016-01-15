#! /bin/bash

cd "$(dirname "$0")"

source ../../0.General/pass_file

source ../../../ceph_scripts/export_file

source ../../0.General/openstack_functions

source ../../0.General/ceph_openstack_functions

######---------------------------------Glance Database configuration----------------------------------------

####We generate the Glance Database Password


#We run the MySQL function from ../../0.General/openstack_functions
f_mysql glance $glance_DBpass

#################Creating Glance users and roles in Openstack

source /root/admin-openrc.sh

#Create the glance user:
openstack user create --domain default --password $glance_user_pass glance

#Add the admin role to the glance user and service project:
openstack role add --project service --user glance admin

#Create the glance service entity:
openstack service create --name glance \
  --description "OpenStack Image service" image

#Create the Image service API endpoint:
openstack endpoint create --region RegionOne \
  image public http://controller:9292

openstack endpoint create --region RegionOne \
  image internal http://controller:9292

openstack endpoint create --region RegionOne \
  image admin http://controller:9292

###---------------------INSTALL the packages and services--------------

apt-get install -y glance python-glanceclient

cp sources/glance-api.conf /etc/glance/glance-api.conf
chown glance.glance /etc/glance/glance-api.conf

cp sources/glance-registry.conf /etc/glance/glance-registry.conf
chown glance.glance /etc/glance/glance-registry.conf

sed -i "s/DB_pass/${glance_DBpass}/g" /etc/glance/glance-api.conf

sed -i "s/GLANCE_USER_PASS/${glance_user_pass}/g" /etc/glance/glance-api.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/glance/glance-api.conf

sed -i "s/DB_pass/${glance_DBpass}/g" /etc/glance/glance-registry.conf

sed -i "s/GLANCE_USER_PASS/${glance_user_pass}/g" /etc/glance/glance-registry.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/glance/glance-registry.conf

#------Ceph config------------------------------------------------------------------------#
###To choose between ceph or local image directory
loop=true
while [ "$loop" = true ]
do
	echo -e "\nSelect the storage method that you want to use:\n"
        echo -e "1)ceph Storage\n2)Local Storage"
        read -p "Enter the number: " storage_answer

	if [ "$storage_answer" = "1" ]
	then
		f_ceph_glance
	
		sed -i "s/#hw_scsi_model/hw_scsi_model/g" /etc/glance/glance-api.conf
		sed -i "s/#hw_disk_bus/hw_disk_bus/g" /etc/glance/glance-api.conf
		sed -i "s/#hw_qemu_guest_agent/hw_qemu_guest_agent/g" /etc/glance/glance-api.conf
		sed -i "s/#os_require_quiesce/os_require_quiesce/g" /etc/glance/glance-api.conf
	
		sed -i "s/#rbd_store_pool/rbd_store_pool/g" /etc/glance/glance-api.conf
		sed -i "s/#rbd_store_user/rbd_store_user/g" /etc/glance/glance-api.conf
		sed -i "s/#rbd_store_ceph_conf/rbd_store_ceph_conf/g" /etc/glance/glance-api.conf
		sed -i "s/CLUSTER_NAME/$cluster_name/g" /etc/glance/glance-api.conf
		sed -i "s/#rbd_store_chunk_size/rbd_store_chunk_size/g" /etc/glance/glance-api.conf
	
		sed -i "s/CEPH/rbd/g" /etc/glance/glance-api.conf
		sed -i "s/STORES/glance.store.rbd.Store/g" /etc/glance/glance-api.conf
		loop=false

	elif [ "$storage_answer" = "2" ]
	then
		sed -i "s/CEPH/file/g" /etc/glance/glance-api.conf
		sed -i "s/STORES/glance.store.filesystem.Store/g" /etc/glance/glance-api.conf
		sed -i "s/#filesystem_store_datadir/filesystem_store_datadir/g" /etc/glance/glance-api.conf
		loop=false

	else
		echo -e "\n"
        	read -p "Invalid input. Press any key to reload menu: " fake
        	loop=true

	fi
done
#-----------------------------------------------------------------------------------------#
su -s /bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart

rm -f /var/lib/glance/glance.sqlite

####---------------------------Verification process-------------

read -p "We are going to run the verification process: [Press any key] " fake


echo "export OS_IMAGE_API_VERSION=2" >> /root/admin-openrc.sh 
echo "export OS_IMAGE_API_VERSION=2" >> /root/demo-openrc.sh

source /root/admin-openrc.sh

env | grep OS
env | grep pass


mkdir /tmp/images

wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

glance image-create --name "cirros-0.3.4-x86_64" --file /tmp/images/cirros-0.3.4-x86_64-disk.img \
  --disk-format raw --container-format bare --visibility public --progress

glance image-list

rm -rf /tmp/images


echo -e "\nGlance installation is completed\n"
