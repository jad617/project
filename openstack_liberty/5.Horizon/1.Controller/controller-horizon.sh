#! /bin/bash

apt-get install -y openstack-dashboard

cp sources/local_settings.py /etc/openstack-dashboard/local_settings.py
chown root.root /etc/openstack-dashboard/local_settings.py

sed -i "s/CONTROLLER/$HOSTNAME/g" /etc/openstack-dashboard/local_settings.py

service apache2 reload

