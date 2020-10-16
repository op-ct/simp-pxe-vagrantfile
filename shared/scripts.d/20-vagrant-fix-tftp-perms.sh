#!/bin/sh

# Fix broken TFTP dir permissions
ls -lart /var/lib/tftpboot/linux-install
ls -lartZ /var/lib/tftpboot/linux-install
###chmod go=u-w -R /var/lib/tftpboot/linux-install

# Find stuff
yum install -y mlocate
updatedb
