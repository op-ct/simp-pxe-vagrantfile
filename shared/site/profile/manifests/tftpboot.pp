# Note the difference in the `extra` arguments here.
class profile::tftpboot(
  Stdlib::IP::Address $ip=$facts['ipaddress'],

) {
  include '::tftpboot'

  tftpboot::linux_model { 'el8_x86_64':
    kernel => 'centos-8-x86_64/vmlinuz',
    initrd => 'centos-8-x86_64/initrd.img',
    ks     => "https://10.0.71.106/ks/pupclient_x86_64__el8.cfg",
    extra  => "inst.noverifyssl"
  }

  tftpboot::linux_model { 'el7_x86_64':
    kernel => 'centos-7-x86_64/vmlinuz',
    initrd => 'centos-7-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64.cfg",
    extra  => "inst.noverifyssl ksdevice=bootif\nipappend 2"
  }

  tftpboot::linux_model { 'el6_x86_64':
    kernel => 'centos-6-x86_64/vmlinuz',
    initrd => 'centos-6-x86_64/initrd.img',
    ks     => "https://${ip}/ks/pupclient_x86_64.cfg",
    extra  => "noverifyssl ksdevice=bootif\nipappend 2"
  }

  tftpboot::assign_host { 'default': model => "el${facts['os']['release']['major']}_x86_64" }
  tftpboot::assign_host { '01-aa-bb-cc-cc-00-28': model => 'el8_x86_64' }
  tftpboot::assign_host { '01-aa-bb-cc-cc-00-27': model => 'el7_x86_64' }
  tftpboot::assign_host { '01-aa-bb-cc-cc-00-26': model => 'el6_x86_64' }


}
