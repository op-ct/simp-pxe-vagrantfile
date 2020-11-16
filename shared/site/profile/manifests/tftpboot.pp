# Note the difference in the `extra` arguments here.
class profile::tftpboot(
  Stdlib::IP::Address $ip=$facts['ipaddress'],
  Boolean   $fips = false,
  String[1] $el8_boot_hash = 'grub.pbkdf2.sha512.10000.94454C752918769A415DB7949779653CA87DC7D4B21C4E531F5E53CF16DE397CA8BA8BF758019D5F299717D59E4598040FBA0B3039FA757E033A9ED0E37A7FEF.BA03CF7EAEF494D86C79BBEDDF308C23FD359FC31F63851CE28CDEC0D8B3A278B392136BE8E4F1D9028EC8B90C13908B2438385AA8890E0DF2D1E35CFC6B2788',
  String[1] $el8_root_hash = '$6$58rp5hrn$Rv/tzwlVBS5oHsKXPwcMzohyFzehtOC9HB502E9j8fjPeujf3cd9THmKODO39Y0Fhnimj5AZ.OXu3GByImjDH.',
  String[1] $el6_boot_hash = '6$CxRbPTshtrVhiKe5$zJTrzr7kLP.rvMNJyCz8yOdYNpgIbjMifLTAlH/UADYOFMW9Nflf6SyPvCMEGnBCtP80bmYGLrmD/7nxf2mz/1',
  String[1] $el6_root_hash = '$6$n5tzmels$1Rz0I5MO.YKYQPd/GhkU6sKOgEe/.vjz7K40XtB5VLHPgj6PIkbn9AGBljS9KdHOfe.0CoDDLz7T6ye/BG2Yg1',
) {
  include '::tftpboot'

  tftpboot::linux_model { 'el8_x86_64_bios':
    kernel => 'centos-8-x86_64/vmlinuz',
    initrd => 'centos-8-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64__CentOS8_bios.cfg",
    extra  => "inst.noverifyssl",
    fips   => $fips,
  }

  tftpboot::linux_model { 'el7_x86_64_bios':
    kernel => 'centos-7-x86_64/vmlinuz',
    initrd => 'centos-7-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64.cfg",
    extra  => "inst.noverifyssl ksdevice=bootif\nipappend 2",
    fips   => $fips,
  }

  tftpboot::linux_model { 'el6_x86_64_bios':
    kernel => 'centos-6-x86_64/vmlinuz',
    initrd => 'centos-6-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64__CentOS6_bios.cfg",
    extra  => "noverifyssl ksdevice=bootif\nipappend 2",
    fips   => $fips,
  }

  tftpboot::linux_model_efi { 'el8_x86_64_efi':
    kernel => 'centos-8-x86_64/vmlinuz',
    initrd => 'centos-8-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64__CentOS8_efi.cfg",
    extra  => "inst.noverifyssl",
    fips   => $fips,
  }

  tftpboot::linux_model_efi { 'el7_x86_64_efi':
    kernel => 'centos-7-x86_64/vmlinuz',
    initrd => 'centos-7-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64.cfg",
    extra  => "inst.noverifyssl",
    fips   => $fips,
  }

  tftpboot::linux_model_efi { 'el6_x86_64_efi':
    kernel      => 'centos-6-x86_64/vmlinuz',
    initrd      => 'centos-6-x86_64/initrd.img',
    ks          => "https://${ip}/ks/pupclient_x86_64__CentOS6_efi.cfg",
    extra       => "noverifyssl",
    fips        => $fips,
    legacy_grub => true,
  }
  tftpboot::assign_host { 'default': model => "el${facts['os']['release']['major']}_x86_64" }
  tftpboot::assign_host { '01-aa-bb-cc-cc-00-28': model => 'el8_x86_64_bios' }
  tftpboot::assign_host { '01-aa-bb-cc-cc-00-27': model => 'el7_x86_64_bios' }
  tftpboot::assign_host { '01-aa-bb-cc-cc-00-26': model => 'el6_x86_64_bios' }
  tftpboot::assign_host_efi { '01-aa-bb-cc-cc-00-23': model => 'el8_x86_64_efi' }
  tftpboot::assign_host_efi { '01-aa-bb-cc-cc-00-22': model => 'el7_x86_64_efi' }
  tftpboot::assign_host_efi { '01-aa-bb-cc-cc-00-21': model => 'el6_x86_64_efi' }


  [8,6].each |$rel| {
    case $rel {
      8: { $boot_hash = $el8_boot_hash; $root_hash = $el8_root_hash }
      6: { $boot_hash = $el6_boot_hash; $root_hash = $el6_root_hash }
      default: { $boot_hash = $el8_boot_hash; $root_hash = $el8_root_hash }
    }
    ['bios', 'efi'].each |$fw| {
    # NOTE - The hashed credentials are what simp-packer grants its test boxes
      file{"/var/www/ks/pupclient_x86_64__CentOS${rel}_${fw}.cfg":
        owner   => 'root',
        group   => 'apache',
        mode    => '0640',
        content => epp("${module_name}/ks/CentOS/${rel}/pupclient_x86_64.cfg.epp", {
          boot_pass_hash => $boot_hash,
          root_pass_hash => $root_hash,
          ks_server_ip   => $ip,
          yum_server_ip  => $ip,
          linux_dist     => 'CentOS',
          fips           => $fips,
          efi            => ($fw == 'efi'),
        })
      }

      # Re-create the "template" for simp-core
      file{"/vagrant/pupclient_x86_64__CentOS${rel}_${fw}.cfg":
        owner   => 'vagrant',
        group   => 'vagrant',
        mode    => '0644',
        content => epp("${module_name}/ks/CentOS/8/pupclient_x86_64.cfg.epp", {
          boot_pass_hash => '#BOOTPASS#',
          root_pass_hash => '#ROOTPASS#',
          ks_server_ip   => '#KSSERVER#',
          yum_server_ip  => '#YUMSERVER#',
          linux_dist     => '#LINUXDIST#',
          fips           => $fips,
          efi            => ($fw == 'efi'),
        })
      }
    }
  }

  file{'/var/www/ks/repodetect.sh':
    owner  => 'root',
    group  => 'apache',
    mode   => '0640',
    source => "puppet:///modules/${module_name}/ks/repodetect.sh",
  }

  # Re-create the "template" for simp-core
  file{'/vagrant/pupclient_x86_64__CentOS8.cfg':
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0644',
    content => epp("${module_name}/ks/CentOS/8/pupclient_x86_64.cfg.epp", {
      boot_pass_hash => '#BOOTPASS#',
      root_pass_hash => '#ROOTPASS#',
      ks_server_ip   => '#KSSERVER#',
      yum_server_ip  => '#YUMSERVER#',
      linux_dist     => '#LINUXDIST#',
    })
  }

  file{'/vagrant/pupclient_x86_64__CentOS6.cfg':
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0644',
    content => epp("${module_name}/ks/CentOS/6/pupclient_x86_64.cfg.epp", {
      boot_pass_hash => '#BOOTPASS#',
      root_pass_hash => '#ROOTPASS#',
      ks_server_ip   => '#KSSERVER#',
      yum_server_ip  => '#YUMSERVER#',
      linux_dist     => '#LINUXDIST#',
    })
  }
}
