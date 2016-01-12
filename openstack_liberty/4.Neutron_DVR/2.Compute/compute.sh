#! /bin/bash

echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf

echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf

modprobe br_netfilter

sysctl -p

apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent

cp ./neutron.conf /etc/neutron/neutron.conf

chown root.neutron /etc/neutron/neutron.conf

cp ./ml2_conf.ini /etc/neutron/plugins/ml2/
chown root.neutron /etc/neutron/plugins/ml2/ml2_conf.ini

read -p "What is the IP inside the neutron server?: " ip_compute
sed -i "s/local_ip =/local_ip = $ip_compute/g" /etc/neutron/plugins/ml2/ml2_conf.ini

service openvswitch-switch restart

service nova-compute restart

service neutron-plugin-openvswitch-agent restart

echo -e "\n Compute networking setup is done\n"
