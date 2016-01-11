#! /bin/bash


cd "$(dirname "$0")"

#------------------------------Ceph Pool Configuration--------------------------------------

bash ../../../ceph_scripts/sources/ceph_pool

#------------------------------Configuaration of the /etc/hosts file------------------------

#bash ../../0.General/hosts.sh
#Was moved to /root/project/system_prep
#------------------------------Configuration of the nagios NRPE service----------------------

#bash ../../0.General/nagios_install.sh
#Was moved to /root/project/system_prep

#------------------------------Step-1 Installation on Controller node------------------------

bash ../../0.General/controller_packages


