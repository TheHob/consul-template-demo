//  The region we will deploy our cluster into.
variable "region" {
  description = "Consul Cluster deployment region"
  default = "us-east-1"
}

// Add the location of your credentials here
variable "aws_cred_file" {
  description = "Location of AWS credentials"
  default = "~/.aws/credentials"
}

// Your AWS deploy key
variable "key_name" {
  description = "Name of the deploy/SSH key to create in order to access hosts."
}

variable "public_key" {
  description = "Public portion of the deploy key to create in order to access hosts. Sensitive variable."
}

variable "private_key" {
  description = "Contents of private key to access hosts. Sensitive variable. Hint: export TF_VAR_private_key=$(cat private_key.pem)"
}

// AMI id that will be used to build a consul cluster
// with consul installed and puppet boostrapped
variable "server_ami" {
  default = {
    us-east-1-centos7 = "ami-01558cebad47c7a9a"
  }
}

// AMI ID here that will be used to build hosts with
// puppet and the consul agent bootstrapped
variable "client_ami" {
  default = "ami-0b85f12802faa0e0a"
}

variable "platform" {
  default = "centos7"
}

variable "security_groups" {
  default = ["consul_centos7"]
}

// Give your cluster a name
variable "cluster_name" {
  default     = "development"
  description = "Give your cluster a name."
}

output "Haproxy_Address" {
    value = "http://${aws_instance.haproxy.public_dns}"
}

output "Consul_Server_Address" {
    value = "http://${module.consul.server_address}:8500"
}

output "Web_Host_Addresses" {
    value = "${aws_instance.web.*.public_dns}"
}
