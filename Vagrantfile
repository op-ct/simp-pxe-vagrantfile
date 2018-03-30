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


    # SIMP locks down its partitions so tightly that every location that
    # vagrant can upload files to and execute from is `noexec`!
    #
    # We solve this problem by having Vagrant create the "synced" folder
    # `/vagrant` on the VM before we start running scripts.
    #
    # The syncing is a nice side-effect, but the local `shared/`folder is not
    # required to actually exist.
    v.vm.synced_folder 'shared', '/vagrant',
                       create: true,
                       type:   'rsync',
                       rsync_exclude: '.git/'

    # Let's dedicate an internal network to PXE booting without noise
    v.vm.network :private_network,
                 ip:                  '192.168.102.7',
                 netmask:             '255.255.255.0',
                 name:                'vboxnet2',
                 mac:                 'aaccccbb0007',
                 auto_config:         false,
                 virtualbox__intnet:  'pxe_network'

    v.vm.provider :virtualbox do |vb|
      vb.gui = 'true'
      vb.customize [
        'modifyvm', :id,
        '--memory', '4096',
        '--cpus', '2',
        '--natdnshostresolver1', 'on',
        '--audio', 'null' # prevents VirtualBox from locally blocking ALSA
      ]
    end

    # NOTE: upload_path is under /vagrant so the script can be executed
    v.vm.provision 'set up local internet and classify server21',
                   type: 'shell',
                   upload_path: '/vagrant/vagrant-shell.sh',
                   inline: <<-EOCMD
#!/bin/bash

bash /vagrant/scripts/enable_nat_nic_during_kickstart.sh
bash /vagrant/scripts/add_helpers_to_bashrc.sh

set -x
# TODO: possiblity for a more robust fix: simp-packer
ip route add default via 10.0.2.3

bash /vagrant/scripts/deliver_new_puppet_content.sh

puppet agent -t
true
         EOCMD
  end

  # original ref: https://github.com/eoli3n/vagrant-pxe/blob/master/client/Vagrantfile
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
    pxe_client.vm.network 'forwarded_port', guest: 80,  host: 8080, auto_correct: true
    pxe_client.vm.provider :virtualbox do |vb|
      # PXE client RAM *MUST* be over 1024 because of an EL7 quirk
      vb.memory = '2048'
      vb.cpus   = '2'
      vb.gui    = 'true'

      vb.customize [
        'modifyvm', :id,
        '--nicbootprio2', '1', # 1=highest PXE boot priority
        '--nicbootprio1', '0', # 0=lowest priority (I can't find a way to stop
                               #   a specific NIC from PXE-booting, period)
        '--boot1', 'disk',     # boot from disk after pxe kickstart
        '--boot2', 'net',      # PXE boot if disk is blank
        '--boot3', 'none',
        '--boot4', 'none',
        '--audio', 'null'      # prevent VirtualBox from locally blocking ALSA
      ]
    end
  end
end
# vim: set syntax=ruby ts=2 sw=2 et:
