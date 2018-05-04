node default {

  class { '::consul':
    config_hash => {
      'data_dir'   => '/opt/consul/data',
      'datacenter' => 'dc1',
      'log_level'  => 'INFO',
      'node_name'  => $::hostname,
      'retry_join' => ["${consul_join_address}"],
    }
  }

}
