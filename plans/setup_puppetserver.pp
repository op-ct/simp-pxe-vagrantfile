# vagrant bolt plan run simp_pxe_test::setup_puppetserver --log_level debug --verbose
# bolt plan run simp_pxe_test::setup_puppetserver --no-host-key-check --tty --user vagrant --password vagrant --run-as root puppetserver=ssh://127.0.0.1:2202
plan simp_pxe_test::setup_puppetserver(
  TargetSpec            $puppetserver = get_targets('puppetserver'),
  Stdlib::Absolutepath  $project_dir  = system::env('PWD'),
  Hash                  $config       = loadyaml("${project_dir}/Vagrantfile.yaml"),
  Boolean               $unpack       = true,
#  Optional[TargetSpec]                $clients              = undef,
#  Integer                             $release              = 6,
#  Enum['stable','unstable','rolling'] $release_type         = 'stable',
#  String                              $simp_release_package = 'https://download.simp-project.com/simp-release-community.rpm',
#  Boolean                             $force                = false
) {

  # Ensure transport settings work with a locked-down SIMP vagrant box
  # We're doing this here because `vagrant bolt` generates its own inventory.yaml
  # and we won't be able to affect the transport options there
  # ----------------------------------------------------------------------------
  $tmpdir = '/vagrant'
  $transport_defaults = { 'run-as' => 'root', 'tmpdir' => "${tmpdir}/tmp" }
  $puppetserver.each |$t| {
    $ssh_defaults = $t.config['ssh'].merge($transport_defaults)
    $transport =  $t.set_config('ssh', $ssh_defaults)
  }
  run_command( "mkdir -p '${tmpdir}/tmp'", $puppetserver,
    'Create a clean tmp directory for bolt login',
    {'_run_as' => 'vagrant', 'tmp_dir' => $tmpdir}
  )
  # ----------------------------------------------------------------------------

  run_task(
    'simp_pxe_test::copy_shared_files', $puppetserver,
    'Copy important files from /vagrant to OS (/root, Puppet profiles, Hiera)'
  )

  run_task(
    'simp_pxe_test::update_hiera_data', $puppetserver,
    'Update Hiera data.  Currently: replaces site::tftpboot with profile::tftpboot'
  )

  # Install convenient packages
  # ----------------------------------------------------------------------------
  apply( $puppetserver, { '_description' => 'Install convenient packages' } ){
    package{ ['mlocate','vim-enhanced','git','jq','createrepo_c']:
      ensure                             => installed,
    }
    Package['mlocate'] ~> exec{'/usr/bin/updatedb':
      refreshonly                        => true,
    }
  }

  # Unpack DVDs
  # ----------------------------------------------------------------------------
  if $unpack {
    $config.dig('os_iso_files').lest || {{}}.each |$iso_file,$iso_version | {
      out::message("ISO: ${iso_file.basename} (${iso_version})")
      $isos_dir =  $config.dig('isos_dir').lest || { '/var/simp/ISOs' }
      run_command(
        "/usr/bin/test -f '${iso_file}' && /usr/local/bin/unpack_dvd --unpack-pxe --unpack-yum -v '$iso_version' '${isos_dir}/${$iso_file.basename}'",
        $puppetserver,
        "unpack_dvd ${iso_file.basename} ${iso_version}"
      )
    }
  }

  # Run `puppet agent -t`
  # ----------------------------------------------------------------------------
  $pup_res =  run_command(
    '/opt/puppetlabs/puppet/bin/puppet agent -t', $puppetserver,
    'Apply changes with `puppet agent -t` (will probably take a while)',
    { '_catch_errors' =>  ['puppetlabs.tasks/command-error'] }
  )

  # Exit codes 0 and 2 from a `puppet agent -t` are okay; otherwise fail
  $pup_res.filter |$r| {
    $r.status == 'failure' and $r.value['exit_code'] != 2
  }.map |$r| { $r.value['_error'] }.each |$err| {
    fail_plan($err['msg'], $err['kind'], $err['details'], $err['issue_code'] )
  }

  out::message('FINIS')
}
