resource "aws_instance" "server" {
    ami = "${lookup(var.ami, "${var.region}-${var.platform}")}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    count = "${var.servers}"
    security_groups = ["${aws_security_group.consul.name}"]

    connection {
        user = "${lookup(var.user, var.platform)}"
        private_key = "${var.private_key}"
    }

    #Instance tags
    tags {
        Name = "${var.tagName}-${count.index}"
        ConsulRole = "Server"
    }

    provisioner "file" {
        source = "${path.module}/shared/scripts/${lookup(var.service_conf, var.platform)}"
        destination = "/tmp/${lookup(var.service_conf_dest, var.platform)}"
    }

    # Additional config files
    # Not ideal, only for the purposes of the tech exercise
    provisioner "file" {
        source = "./config/consul.d"
        destination = "/tmp/consul.d"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo rsync -avz --delete /tmp/consul.d/ /etc/systemd/system/consul.d",
        ]
    }


    provisioner "remote-exec" {
        inline = [
            "echo ${var.servers} > /tmp/consul-server-count",
            "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/shared/scripts/install.sh",
            "${path.module}/shared/scripts/service.sh",
            "${path.module}/shared/scripts/ip_tables.sh",
        ]
    }
}

resource "random_id" "security_group" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    cluster_name = "${var.cluster_name}"
  }

  byte_length = 8
}

resource "aws_security_group" "consul" {
    name = "consul_${var.platform}_${var.cluster_name}_${random_id.security_group.hex}"
    description = "Consul internal traffic + maintenance."

    // This is for outbound internet access
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // These are for internal traffic
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        self = true
    }

    // Allow all for test purposes
    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // These are for maintenance
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // This is for outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
