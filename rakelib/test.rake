require 'pry'

def sh_or_pry(cmd)
  sh(cmd){ |ok,res| binding.pry unless ok }
end

def sh_or_ignore(cmd)
  sh(cmd){ |ok,res| warn("  (failed: #{res})") unless ok }
end

desc 'rsync + redo puppetserver setup (skip unpack), destroy and redo all pxe agents'
task :redo do
  sh_or_pry 'vagrant rsync puppetserver'
  sh_or_pry 'vagrant bolt plan show --log_level debug --verbose'
  sh_or_pry 'vagrant bolt plan run simp_pxe_test::setup_puppetserver --log_level debug --verbose unpack=false'
  [8,7,6].each do |n|
    sh_or_ignore "vagrant destroy pxe#{n} -f"
    sh_or_ignore %Q[vagrant ssh puppetserver -c 'sudo su - -c "puppetserver ca clean --certname server2#{n}.simp.test"']
  end
end
