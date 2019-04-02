# Create a consul-supported web application 
resource "aws_instance" "web" {
  ami             = "${var.client_ami}"
  instance_type   = "t2.micro"
  depends_on      = ["module.consul"]
  key_name        = "${var.key_name}"
  count           = "5"
  security_groups = ["${module.consul.security_group}"]
  connection {
      user = "centos"
      private_key = "${var.private_key}"
  }

  # Manifest to install consul agent, join cluster
  # and configure http check using puppet
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
  ::consul::service { 'web':
    checks  => [
      {
        script   => 'curl localhost >/dev/null 2>&1',
        interval => '10s'
      }
    ],
    port => 80,
    tags => ['HTTP'],
  }
}
EOF
    destination = "/tmp/consul_client.pp"
  }

  # Manifest to install apache with puppet
  provisioner "file" {
    source      = "manifests/apache.pp"
    destination = "/tmp/apache.pp"
  }

  # Configure and run consul agent, install apache
  provisioner "remote-exec" {
      inline = [
          "sudo puppet apply /tmp/consul_client.pp",
          "sudo puppet apply /tmp/apache.pp",
      ]
  }

  # Website index template file
  provisioner "file" {
    source = "config/httpd/index.html.tpl",
    destination = "/tmp/index.html.tpl"
  }

  # Create an upstart file for consul-template
  provisioner "file" {
    source = "config/consul-template/upstart/consul-template.service"
    destination = "/tmp/consul-template.service"
  }

  # Write a config file for consul-template template/monitors
  # TODO: Put this in a template
  provisioner "file" {
    content = <<EOF
consul = "${module.consul.server_address}:8500"
template {
  source      = "/root/index.html.tpl"
  destination = "/var/www/html/index.html"
  command     = "sed -i 's/HOSTNAME/ACTUAL/g' /var/www/html/index.html"
}
EOF
    destination = "/tmp/consul-template.json"
  }

  provisioner "file" {
    source = "config/httpd/images"
    destination = "/tmp"
  }

  # Move index template, images, upstart and consul-template configs into place
  # Start consul-template monitoring (monitoring web service via consul)
  provisioner "remote-exec" {
      inline = [
          "sudo mv /tmp/images /var/www/html/images",
          "sudo mkdir -p /etc/consul-template.d",
          "sudo rsync -avz /tmp/index.html.tpl /root/index.html.tpl --delete",
          "sudo rsync -avz /tmp/consul-template.json /etc/consul-template.d/consul-template.json --delete",
          "sudo rsync -avz /tmp/consul-template.service /usr/lib/systemd/system/consul-template.service --delete",
          "sudo sed -i \"s/ACTUAL/`hostname`/g\" /etc/consul-template.d/consul-template.json",
          "sudo systemctl start consul-template",
      ]
  }

  # Node for checking web cluster status
  tags {
    Name = "WebServiceStatusNode"
  }
}
