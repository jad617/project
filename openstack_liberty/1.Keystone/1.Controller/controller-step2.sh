#! /bin/bash

cd "$(dirname "$0")"

#------------------------------MySQL installation------------------------------------------------

bash ../../0.General/mysql_install

source ../../0.General/pass_file

source ../../0.General/openstack_functions
#------------------------------MongoDB Installation------------------------------------------------#
bash ../../0.General/mongodb_install

###----------------------------Messaging Queue Installation------------------------------------------
bash ../../0.General/rabbit_install

######---------------------------------Identity Database configuration----------------------------------------

#We create the MySQL DB

f_mysql keystone $keystone_DBpass


###---------------------------------Keystone Installation--------------------------------

echo "manual" > /etc/init/keystone.override

apt-get install -y keystone apache2 libapache2-mod-wsgi memcached python-memcache

cp sources/keystone.conf /etc/keystone/keystone.conf
chown root.root /etc/keystone/keystone.conf


sed -i "s/ADMIN_TOKEN/${TOKEN}/g" /etc/keystone/keystone.conf

sed -i "s/KEYSTONE_DBPASS/${keystone_DBpass}/g" /etc/keystone/keystone.conf

su -s /bin/sh -c "keystone-manage db_sync" keystone

echo -e "\nKeystone Installation completed\n"

#-------------------------------Apache Configuration----------------------------------------------

cp sources/wsgi-keystone.conf /etc/apache2/sites-available/wsgi-keystone.conf
cp sources/apache2.conf /etc/apache2/apache2.conf

chown root.root /etc/apache2/sites-available/wsgi-keystone.conf
chown root.root /etc/apache2/apache2.conf

ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled

#mkdir -p /var/www/cgi-bin/keystone

#curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo \
#  | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin

#chown -R keystone:keystone /var/www/cgi-bin/keystone
#chmod 755 /var/www/cgi-bin/keystone/*

service apache2 restart

rm -f /var/lib/keystone/keystone.db


echo -e "\nApached Configured\n"

#------------------------------Create the service entity and API endpoint-------------------

export OS_TOKEN=${TOKEN}
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3


#Create the service entity for the Identity service:
openstack service create \
  --name keystone --description "OpenStack Identity" identity

#Create the Identity service API endpoint:
openstack endpoint create --region RegionOne \
  identity public http://controller:5000/v2.0

openstack endpoint create --region RegionOne \
  identity internal http://controller:5000/v2.0

openstack endpoint create --region RegionOne \
  identity admin http://controller:35357/v2.0

#Create the admin project:
openstack project create --domain default \
  --description "Admin Project" admin

#Create the admin user:
openstack user create --domain default --password $admin_pass admin

#Create the admin role
openstack role create admin

#Add the admin role to the admin project and user:
openstack role add --project admin --user admin admin

#Create the service project:
openstack project create --domain default --description "Service Project" service

#Create the demo project:
openstack project create --domain default --description "Demo Project" demo

#Create the demo user
openstack user create --domain default --password $demo_pass demo

#Create the user role:
openstack role create user

#Add the user role to the demo project and user:
openstack role add --project demo --user demo user

echo -e "\n Indentity installation and configuration is 100% done!!!\n"


#------------------Creating the EXPORT FILES-----------------------------

###Admin Export file
echo "#! /bin/bash
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${admin_pass}
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
" > /root/admin-openrc.sh

if [ -f /root/admin-openrc.sh ]
then
	chmod 700 /root/admin-openrc.sh
else
	echo "There is no admin-openrc.sh"
fi

###Demo export file

echo "#! /bin/bash
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=${demo_pass}
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
" > /root/demo-openrc.sh

if [ -f /root/demo-openrc.sh ]
then
	chmod 700 /root/demo-openrc.sh
else
        echo "There is no demo-openrc.sh"
fi

#======================Indentity Finished================================

########-----VERIFY OPERATION TO BE SURE THAT EVERYTHING WORKS---############

read -p "We are going to proceed with the verification steps, Press any key to continue?" fake

unset OS_TOKEN
unset OS_URL

openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-id default --os-user-domain-id default \
  --os-project-name admin --os-username admin --os-auth-type password \
  --os-password $admin_pass token issue

if [ "$?" -ne 0 ]
then
	echo -e "\nThere is an error with the setup, please review your configs\n"
else
	echo -e "\nFirst verification successful!!!\n"
fi

openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-id default --os-user-domain-id default \
  --os-project-name demo --os-username demo --os-auth-type password \
  --os-password $demo_pass token issue

if [ "$?" -ne 0 ]
then
        echo -e "\nThere is an error with the setup, please review your configs\n"
else
        echo -e "\nSecond verification successful!!!\n\nYou cand now proceed to the next step\n"

fi


echo -e "\nScript Done\n"
