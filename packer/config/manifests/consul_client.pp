node default {

  file { '/opt/consul':
    ensure => directory,
  }

  $packages = ['zip', 'unzip', 'gzip']

  package { $packages:
    ensure => installed,
  }

}
