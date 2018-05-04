#/bin/sh

sudo yum -y install haproxy
echo "${module.consul.server_address}" > /tmp/test.file
