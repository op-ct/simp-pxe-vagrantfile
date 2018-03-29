# README
#
# To begin with, run:
#
#     vagrant up puppetserver
#
# When the puppet server is ready, run:
#
#     vagrant up pxe_client
#


if ARGV[0] == 'up' && ARGV.size == 1
  fail <<-EEE.gsub(/^ {4}/,'')
    ERROR: Do not run 'vagrant up' without specifying a VM.

      To begin with, run:

          vagrant up puppetserver

      When the puppet server is ready, run:

          vagrant up pxe_client
  EEE
end

Vagrant.configure('2') do |c|
  c.ssh.insert_key = false

  c.vm.define 'puppetserver', primary: true do |v|
    v.vm.box = 'SIMP6.1-CENTOS7-NOFIPS-RELEASE.box'
    v.vm.box_check_update = 'false'

    # This establishes `/vagrant`, so the vagrant SSH user can upload and exec
    # `shell` provisioner files.  SIMP locks down its partitions so tightly
    # that every other location that vagrant can upload files to is `noexec`!
    #
    # The local `shared/` folder is not required to actually exist.
    v.vm.synced_folder 'shared', '/vagrant', create: true, type: 'rsync', rsync_exclude: '.git/'
    v.vm.network :private_network,
                 ip:                  '192.168.102.7',
                 netmask:             '255.255.255.0',
                 name:                'vboxnet2',
                 mac:                 'aaccccbb0007',
                 auto_config:         false,
                 virtualbox__intnet:  'pxe_network'

    v.vm.provider :virtualbox do |vb|
      vb.gui = 'true'
      vb.customize([
                     'modifyvm', :id,
                     '--memory', '4096',
                     '--cpus', '2',
                     '--natdnshostresolver1', 'on',
                     # prevents VirtualBox from blocking ALSA on the local host
                     '--audio', 'null'
                   ])

      vb.customize ['modifyvm', :id, '--vrde', 'on']
      vb.customize ['modifyvm', :id, '--vrdeauthtype', 'null']
      vb.customize ['modifyvm', :id, '--vrdeproperty', 'Security/Method=negotiate']
      vb.customize ['modifyvm', :id, '--vrdeproperty', 'Security/CACertificate=/etc/pki/simp/x509/cacerts/cacerts.pem']
      vb.customize ['modifyvm', :id, '--vrdeproperty', 'Security/ServerCertificate=/etc/pki/simp_apps/packer/packer-vagrant.pub']
      vb.customize ['modifyvm', :id, '--vrdeproperty', 'Security/ServerPrivateKey=/etc/pki/simp_apps/packer/packer-vagrant.pem']
    end

    ### TODO: these should be patches to the simp-picker build
    v.vm.provision 'upload_tftpboot.pp',
                   type: 'file',
                   source: './shared/tftpboot.pp',
                   destination: '/vagrant/tftpboot.pp'
    v.vm.provision 'upload_vagrant_ssh.pp',
                   type: 'file',
                   source: './shared/vagrant_ssh.pp',
                   destination: '/vagrant/vagrant_ssh.pp'
    v.vm.provision 'set up local internet and classify server21',
                   type: 'shell',
                   upload_path: '/vagrant/vagrant-shell.sh',
                   inline: <<-EOCMD
#!/bin/bash

modulepath=/etc/puppetlabs/code/environments/simp/modules
hieradatapath=/etc/puppetlabs/code/environments/simp/hieradata

echo "modulepath=${modulepath}" >> /root/.bashrc
echo "hieradatapath=${hieradatapath}" >> /root/.bashrc
echo "ppm=${modulepath}" >> /root/.bashrc
echo "ppms=${modulepath}/site" >> /root/.bashrc
echo "pph=${hieradatapath}" >> /root/.bashrc
echo "pphh=${hieradatapath}/hosts" >> /root/.bashrc
echo "pphg=${hieradatapath}/hostgroups" >> /root/.bashrc

set -x
ip route add default via 10.0.2.3

# TODO: helper to git clone a list of modules at repo/refs
mv "${modulepath}/ssh" /root/ssh.old
git clone https://github.com/simp/pupmod-simp-ssh "${modulepath}/ssh"
git clone https://github.com/simp/pupmod-simp-simp_gitlab "${modulepath}/simp_gitlab"
git clone https://github.com/simp/puppet-gitlab "${modulepath}/gitlab"

cat > ${hieradatapath}/hosts/server21.release.me.yaml <<EEE
---
classes:
- ssh
- site::vagrant_ssh
- simp_gitlab

EEE

cat /vagrant/tftpboot.pp > /etc/puppetlabs/code/environments/simp/modules/site/manifests/tftpboot.pp \
  && echo ============ tftpboot fix = YES || echo ========== tftpboot fix = NO
echo 'site::tftpboot::ip: 192.168.102.7' >> "${hieradatapath}/default.yaml"

cat /vagrant/vagrant_ssh.pp > /etc/puppetlabs/code/environments/simp/modules/site/manifests/vagrant_ssh.pp \
  && echo ============ vagrant_ssh = YES || echo ========== vagrant_ssh = NO

for cmd in chown chmod chcon; do
  ${cmd} -R --reference=/etc/puppetlabs/code/environments/simp/modules/simp "${modulepath}"/{gitlab,simp_gitlab,site,ssh} "${hieradatapath}"/{default.yaml,hosts/server21.release.me.yaml}
done

puppet agent -t

true
         EOCMD
  end

  # cribbed from: https://github.com/eoli3n/vagrant-pxe/blob/master/client/Vagrantfile
  c.vm.define :pxe_client do |pxe_client|
    pxe_client.vm.box = 'empty_box'
    pxe_client.vm.boot_timeout = 3600
    pxe_client.vm.network :private_network,
                          ip:                  '192.168.102.21',
                          netmask:             '255.255.255.0',
                          name:                'vboxnet2',
                          mac:                 'aaccccbb0021',
                          auto_config:         false,
                          virtualbox__intnet:  'pxe_network'

    pxe_client.vm.network 'forwarded_port', guest: 443, host: 8443, auto_correct: true
    pxe_client.vm.network 'forwarded_port', guest: 80, host: 8080, auto_correct: true
    pxe_client.vm.provider :virtualbox do |vb|
      # needs to be *over* 1024 because of an EL7 quirk
      vb.memory = '2048'
      vb.cpus   = '2'
      vb.gui    = 'true'

      vb.customize [
        'modifyvm', :id,
        '--nicbootprio2', '1', # highest priority
        '--nicbootprio1', '0', # lowest priority (seemingly no way to disable)
        '--boot1', 'disk', # boot from disk after pxe kickstart
        '--boot2', 'net',
        '--boot3', 'none',
        '--boot4', 'none',
        '--audio', 'null'
      ]
    end
  end
end
# vim: set syntax=ruby ts=2 sw=2 et:
