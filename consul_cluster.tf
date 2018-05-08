provider "aws" {
  shared_credentials_file = "${var.aws_cred_file}"
  region  = "${var.region}"
}

resource "aws_key_pair" "consul" {
  key_name   = "${var.key_name}"
  public_key = "${var.public_key}"
}

module "consul" {
  source      = "./modules/consul/terraform/aws"
  cluster_name = "${var.cluster_name}"
  key_name    = "${var.key_name}"
  private_key = "${var.private_key}"
  platform    = "${var.platform}"
  ami         = "${var.server_ami}"
  servers     = "3"
}
