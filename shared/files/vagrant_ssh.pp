
class site::vagrant_ssh (
  String $vagrant_key;
){
  file{'/etc/ssh/local_keys/vagrant':
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0640',
    source => 'file:///home/vagrant/.ssh/authorized_keys',
  }
}
