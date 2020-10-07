#!/opt/puppetlabs/puppet/bin/ruby
# ------------------------------------------------------------------------------
# Classify puppetserver to use local profiles
# ------------------------------------------------------------------------------

require 'yaml'
dir = '/etc/puppetlabs/code/environments/production'
hiera_file = File.expand_path('data/hosts/puppet.simp.test.yaml', dir)

data = YAML.load_file(hiera_file)
data['simp::classes'].delete('site::tftpboot')
data['simp::classes'] << 'profile::tftpboot'
data['simp::classes'].uniq!
data['profile::tftpboot::ip'] = '192.168.103.7'

File.open(hiera_file, 'w'){|f| f.puts data.to_yaml }
