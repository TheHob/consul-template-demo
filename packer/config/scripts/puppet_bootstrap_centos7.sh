#!/bin/sh

sudo yum update -y
sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
sudo yum -y install puppet wget zip unzip gzip
sudo puppet module install KyleAnderson-consul --version 2.1.1
sudo puppet module install puppet-archive --version 1.3.0
sudo wget https://releases.hashicorp.com/consul-template/0.18.2/consul-template_0.18.2_linux_amd64.zip
sudo unzip consul-template_0.18.2_linux_amd64.zip
sudo mv consul-template /usr/sbin/.
rm -f consul-template_0.18.2_linux_amd64.zip
