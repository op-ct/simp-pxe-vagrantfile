#!/bin/bash
#
# Alter the kickstart template to configure the kickstarted vagrant VM's NAT
# NIC to access the outside networks.


sed -i -e '/^%post *$/ a\
\
# Configure NAT nic for DHCP\
cat > /etc/sysconfig/network-scripts/ifcfg-enp0s3 <<WAT\
DEVICE=enp0s3\
BOOTPROTO=dhcp\
ONBOOT=yes\
WAT\
\
# Restart nic\
/sbin/ifdown enp0s3\
/sbin/ifup enp0s3\
wait\
sleep 10\
' /var/www/ks/pupclient_x86_64.cfg
