resource "aws_instance" "haproxy" {
  ami           = "${var.client_ami}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  security_groups = ["${module.consul.security_group}"]
  depends_on = ["module.consul"]
  connection {
      user = "centos"
      private_key = "${var.private_key}"
  }
 # Comment for A&E
  # TODO handle this with puppet
  provisioner "remote-exec" {
      inline = [
          "sudo yum -y install haproxy",
          "sudo service haproxy start",
      ]
  }

  # Additional config files
  # TODO: Put the below in a template
  provisioner "file" {
    content = <<EOF
node default {
  class { '::consul':
    config_hash => {
      'data_dir'   => '/opt/consul/data',
      'datacenter' => 'dc1',
      'log_level'  => 'INFO',
      'node_name'  => $::hostname,
      'retry_join' => ["${module.consul.server_address}"],
    }
  }
}
EOF
    destination = "/tmp/consul_client.pp"
  }

  provisioner "remote-exec" {
      inline = [
          "sudo puppet apply /tmp/consul_client.pp",
      ]
  }

  provisioner "file" {
    source = "config/haproxy/haproxy.cfg.tpl",
    destination = "/tmp/haproxy.cfg.tpl"
  }

  provisioner "file" {
    source = "config/consul-template/upstart/consul-template.service"
    destination = "/tmp/consul-template.service"
  }

  provisioner "file" {
    content = <<EOF
consul = "${module.consul.server_address}:8500"
template {
  source      = "/root/haproxy.cfg.tpl"
  destination = "/etc/haproxy/haproxy.cfg"
  command     = "service haproxy restart"
}
EOF
    destination = "/tmp/consul-template.json"
  }

  provisioner "remote-exec" {
      inline = [
          "sudo mkdir -p /etc/consul-template.d",
          "sudo rsync -avz /tmp/haproxy.cfg.tpl /root/haproxy.cfg.tpl --delete",
          "sudo rsync -avz /tmp/consul-template.json /etc/consul-template.d/consul-template.json --delete",
          "sudo rsync -avz /tmp/consul-template.service /usr/lib/systemd/system/consul-template.service --delete",
          "sudo systemctl start consul-template.service",
      ]
  }

  tags {
    Name = "HAProxy"
  }
}
