#! /bin/bash

source ../../0.General/pass_file
source ../../../ceph_scripts/export_file

######---------------------------------Glance Database configuration----------------------------------------

####We generate the Glance Database Password

glanceDB_pass="$(openssl rand -hex 10)"

###We add the password to the ../../0.General/pass_file
echo -e "#GLANCE_DBPASS:\nexport glanceDB_pass=${glanceDB_pass} \n" >> ../../0.General/pass_file
echo -e "#Unset KEYSTONE_DBPASS:\nunset glanceDB_pass=${glanceDB_pass} \n" >> ../../0.General/unset_file

Q1="CREATE DATABASE glance;"
Q2="GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY '${glanceDB_pass}';"
Q3="GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY '${glanceDB_pass}';"
SQL="${Q1}${Q2}${Q3}"


#echo -e "\n"
#read -s -p "What is the root password for MySQL?: " mysql_pass
#echo -e "\n"

#We don't need to add the MySQL password since it has already been done
#echo -e "#MySQL : $mysql_pass\n" >> ../../../../0.General/pass_file

##################TO BE REMOVED AFTER
#mysql -uroot -p"$mysql_pass" -e "DROP DATABASE glance;"     
############### TESTING THE CODE#####
mysql -uroot -p"$mysql_pass" -e "$SQL"

#################Creating Glance users and roles in Openstack

source /root/admin-openrc.sh

#We generate the passwords for the users
glance_user_pass="$(openssl rand -hex 10)"
echo -e "#OpenStack Glance user pass:\nexport glance_user_pass=${glance_user_pass} \n" >> ../../0.General/pass_file
echo -e "#Unset OpenStack Glance user pass:\n unset glance_user_pass=${glance_user_pass}\n" >> ../../0.General/unset_file



#Create the glance user:
openstack user create --password $glance_user_pass  glance

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

sed -i "s/DB_pass/${glanceDB_pass}/g" /etc/glance/glance-api.conf

sed -i "s/GLANCE_USER_PASS/${glance_user_pass}/g" /etc/glance/glance-api.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/glance/glance-api.conf

sed -i "s/DB_pass/${glanceDB_pass}/g" /etc/glance/glance-registry.conf

sed -i "s/GLANCE_USER_PASS/${glance_user_pass}/g" /etc/glance/glance-registry.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/glance/glance-registry.conf

su -s /bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart

rm -f /var/lib/glance/glance.sqlite

####---------------------------Verification process-------------

read -p "We are going to run the verification process: [Press any key] " fake


echo "export OS_IMAGE_API_VERSION=2" >> /root/admin-openrc.sh 
echo "export OS_IMAGE_API_VERSION=2" >> /root/demo-openrc.sh

source /root/admin-openrc.sh

mkdir /tmp/images

wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

glance image-create --name "cirros-0.3.4-x86_64" --file /tmp/images/cirros-0.3.4-x86_64-disk.img \
  --disk-format qcow2 --container-format bare --visibility public --progress

glance image-list

rm -r /tmp/images


echo -e "\nGlance installation is completed\n"

env | grep OS
env | grep pass


