#! /bin/bash


su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service openvswitch-switch restart
service nova-api restart

service openvswitch-switch restart
service neutron-server restart
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart


rm -f /var/lib/neutron/neutron.sqlite


echo -e "\nNeutron setup is done\n"
read -p "We are now going to proceed with the verification. Pres any key to continue: " fake

source /root/admin-openrc.sh

neutron ext-list

neutron agent-list

#------------------------------------------------------------Network Creation Steps---------------------------------

#Create the external network:
#neutron net-create ext-net --router:external \
#  --provider:physical_network external --provider:network_type flat

#Create a subnet on the external network:
#neutron subnet-create ext-net 203.0.113.0/24 --allocation-pool \
#  start=203.0.113.101,end=203.0.113.200 --disable-dhcp \
#  --gateway 203.0.113.1

