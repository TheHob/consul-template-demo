node default {

  file { '/opt/consul':
    ensure => directory,
  }

  $packages = ['zip', 'unzip', 'gzip']

  package { $packages:
    ensure => installed,
  }

  class { '::consul':
    config_hash => {
#      'bootstrap_expect' => 1,
      'client_addr'      => '0.0.0.0',
      'data_dir'         => '/opt/consul/data',
      'datacenter'       => 'dc1',
      'log_level'        => 'INFO',
      'node_name'        => 'server',
      'server'           => true,
      'ui_dir'           => '/opt/consul/data/ui',
    }
  }
}
