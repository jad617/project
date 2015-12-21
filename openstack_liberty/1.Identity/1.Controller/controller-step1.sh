#! /bin/bash

#------------------------------Configuaration of the /etc/hosts file-------------------------

bash ../../0.General/hosts.sh

#------------------------------Configuration of the nagios NRPE service-------------------------

bash ../../0.General/nagios_install.sh

#------------------------------Step-1 Installation on Controller node----------------------------------

bash ../../0.General/controller_packages


