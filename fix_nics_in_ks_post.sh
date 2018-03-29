# Restart nic
cat > /etc/sysconfig/network-scripts/ifcfg-enp0s3 <<WAT
DEVICE=enp0s3
BOOTPROTO=dhcp
ONBOOT=yes
WAT

/sbin/ifdown enp0s3
/sbin/ifup enp0s3
wait
sleep 10

