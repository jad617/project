#!/bin/bash


cd "$(dirname "$0")"

#--------------------------Default entries--------------------------------------

host_file=/etc/hosts

echo "127.0.0.1	localhost" > $host_file
echo "# The following lines are desirable for IPv6 capable hosts" >> $host_file
echo "::1     localhost ip6-localhost ip6-loopback" >> $host_file
echo "ff02::1 ip6-allnodes" >> $host_file
echo "ff02::2 ip6-allrouters" >> $host_file

echo -e "\n#Ips added by the script\n" >> $host_file

#--------------------------Script entries----------------------------------------

reponse=true 

while [ "$reponse" = true ]
do
	echo -e "\nHost File Configuration in /etc/hosts\n"

	read -p "What is the ip of the server to add?: " srv_ip
	read -p "What is its hostname?: " srv_hostname
#	read -p "What is its Domain: " srv_domain
#	echo "$srv_ip	$srv_hostname"."$srv_domain	$srv_hostname" >> $host_file
		
	echo "$srv_ip	$srv_hostname" >> $host_file

#	echo -e "\n" 

	read -p "Would you like to add another Server?: [y/n] " answer
	
#	echo -e "\n"

	if [ "$answer" != "y" ]

	then 
		reponse=false
	else	
		reponse=true
	
	fi

done


#10.0.0.31	compute2
#10.0.0.11	controller
#10.0.0.21	neutron
#10.0.0.41	block1
#10.0.0.31	compute
