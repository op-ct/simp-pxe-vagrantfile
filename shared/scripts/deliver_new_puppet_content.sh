#!/bin/bash

modulepath=/etc/puppetlabs/code/environments/simp/modules
hieradatapath=/etc/puppetlabs/code/environments/simp/hieradata

# TODO: helper to git clone a list of modules at repo/refs (r10k?)
mv "${modulepath}/ssh" /root/ssh.old
git clone https://github.com/simp/pupmod-simp-ssh "${modulepath}/ssh"
git clone https://github.com/simp/pupmod-simp-simp_gitlab "${modulepath}/simp_gitlab"
git clone https://github.com/simp/puppet-gitlab "${modulepath}/gitlab"

cat /vagrant/files/tftpboot.pp > ${modulepath}/site/manifests/tftpboot.pp
cat /vagrant/files/vagrant_ssh.pp > ${modulepath}/site/manifests/vagrant_ssh.pp


# classify server21 (the PXE client)
cat > ${hieradatapath}/hosts/server21.release.me.yaml <<EEE
---
classes:
- ssh
- site::vagrant_ssh
- simp_gitlab

EEE

# Point tftpboot at Puppet master's pxe_network IP
echo 'site::tftpboot::ip: 192.168.102.7' >> "${hieradatapath}/default.yaml"


for cmd in chown chmod chcon; do
  ${cmd} -R --reference=/etc/puppetlabs/code/environments/simp/modules/simp "${modulepath}"/{gitlab,simp_gitlab,site,ssh} "${hieradatapath}"/{default.yaml,hosts/server21.release.me.yaml}
done

