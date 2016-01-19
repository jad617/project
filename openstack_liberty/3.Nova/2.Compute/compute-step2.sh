#! /bin/bash


#We source the passwords
source ../../0.General/pass_file
source ../../../ceph_scripts/export_file

#source ../../0.General/ceph_openstack_functions ###This will be usefull when configuring the Cinder service on the compute

#------------------------------------Step 2 Installation Compute node------------------------------

apt-get install -y nova-compute sysfsutils

cp sources/nova.conf /etc/nova/nova.conf

chown nova.nova /etc/nova/nova.conf

read -p "What is the IP of your server?: " compute_ip

sed -i "s/MY_IP/$compute_ip/g" /etc/nova/nova.conf

sed -i "s/NOVA_PASS/${nova_user_pass}/g" /etc/nova/nova.conf
sed -i "s/RABBIT_PASS/${rabbit_pass}/g" /etc/nova/nova.conf

service nova-compute restart

rm -f /var/lib/nova/nova.sqlite
#------------------------------Ceph Storage Setup-----------------------------
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.cinder | tee /etc/ceph/${cluster_name}.client.cinder.keyring
chown nova.nova /etc/ceph/${cluster_name}.client.cinder.keyring

ceph auth get-key client.cinder | tee client.cinder.key

cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>${secret_uuid}</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF

sudo virsh secret-define --file secret.xml
sudo virsh secret-set-value --secret ${secret_uuid} --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml

echo '
[client]
    rbd cache = true
    rbd cache writethrough until flush = true
    admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok
    log file = /var/log/qemu/qemu-guest-$pid.log
    rbd concurrent management ops = 20
' >> /etc/ceph/${cluster_name}.conf

sed -i "s/CLUSTER_NAME/${cluster_name}/g" /etc/nova/nova.conf
sed -i "s/SECRET_UUID/$secret_uuid/g" /etc/nova/nova.conf

mkdir -p /var/run/ceph/guests/ /var/log/qemu/
chown libvirt-qemu:libvirtd /var/run/ceph/guests /var/log/qemu/

mkdir_ceph_guests="mkdir -p /var/run/ceph/guests/ /var/log/qemu/"
sudo sed -i "11 a $mkdir_ceph_guests" /etc/rc.local

chown_ceph_guests="chown libvirt-qemu:libvirtd /var/run/ceph/guests /var/log/qemu/"
sudo sed -i "12 a $chown_ceph_guests" /etc/rc.local

#-----------------------------------------------------------------------------



service nova-compute restart




echo -e "\nCompute Node 100% installed\n"

echo -e "\nDO NOT FORGET TO DO THE VERIFICATION PROCESS ON THE CONTROLLER NODE!!\n"
