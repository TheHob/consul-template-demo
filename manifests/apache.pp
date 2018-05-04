node default {

  $packages = [ 'httpd', 'httpd-devel' ]

  package { $packages:
    ensure => installed,
  }

  service { 'httpd':
    ensure  => running,
    enable  => true,
    require => Package['httpd'],
  }

}
