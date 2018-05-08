consul-template-demo# Demo: Service Discovery with Consul Template

# This repository will enable you to do the following
- **Create two base images with Packer:**
  - One AMI bootstrapped with puppet and the consul agent minimally configured to run.
  - One AMI boostrapped with puppet and the consul package in preparation to run a consul server.
- **Deploy a consul cluster with Terraform.**
- **Deploy an HAProxy host with Terraform.**
  - HAProxy configuration for backend hosts is monitored by **Consul Template.**
  - Consul Template runs on the HAProxy host, monitoring the `web` service via the Consul server API.
  - When there are new or dead hosts, Consul Template will update and reload HAProxy configurations.
- **Deploy some web instances to which HAProxy will send traffic.**  Consul Template will dynamically manage the pool of web hosts in HAProxy's configuration.
  - Consul Template runs on each web host and monitors the `web` service via the Consul server API.
  - When there are new or dead web hosts, Consul Template detects the change and updates the default `index.html` on each host accordingly.
  - Each web host therefore displays all healthy members of the web application cluster on their default `index.html`.

## Pre-requisites:
- **A Mac running Mac OSX El Capitan or later.**  The demo should work on any platform that has a terminal and can run the tools, but the demo was developed on a Mac.  (Cue 'it worked on my Mac' joke.)
- [Install Packer](https://www.packer.io/docs/install/index.html) version 1.0.0.
- [Install Terraform](https://www.terraform.io/intro/getting-started/install.html) v0.9.2 or later.
- Create a file formatted like the one below that contains **valid AWS credentials.** Credentials for a free account are sufficient.
  ```
  #~/.aws/credentials
  [default]
  aws_access_key_id = "YOURKEY"
  aws_secret_access_key = "YourSecretKeyWhichIsUsuallyLonger"
  region = "us-east-1" # Or whichever region you prefer
  ```
- Name it `credentials` and place it in your home directory: `~/.aws/credentials`.  You can place it elsewhere, this is just where Terraform knows about it by default.
- **Create a similar credentials file for Packer.**  You can put it where you like, as you'll be telling Packer where to find it at run time.  Here's an example:
  ```
  #~/.aws/packer_creds.json
  {
  "aws_access_key_id": "YOURKEY",
  "aws_secret_access_key": "YourSecretKeyWhichIsUsuallyLonger"
  }
  ```
- Make sure you have an **SSH key pair** ready locally. I recommend against using a key pair you already use elsewhere. Instead, create a new pair by doing something like the below:
  ```
  ssh-keygen -t rsa -C "consul@example.com"
  ```  
  This will be important later. Remember where you save the public and private key.
- **Clone this repository.**
  ```
  $ git clone git@github.com:TheHob/consul-template-demo.git
  ```

## Instructions
- **Complete pre-requisites above.**
- **Open a terminal.**
- **Change into the packer directory inside the repository.**
  ```
  cd ~/path/to/consul-template-demo/packer
  ```
- **Let's build two AMIs.** If you prefer not to build new AMIs, you can use the AMIs already specified in `variables.tf` as I've made them public. If you'd like to build new AMIs, run the following (these can be run simultaneously in separate terminal windows):
  ```
  # Build the consul server puppet-bootstrapped AMI
  $ packer build -var-file=/path/to/.aws/packer_creds.json consul_server.json

  # Build the puppet and consul agent-boostrapped AMI
  $ packer build -var-file=/path/to/.aws/packer_creds.json consul_client.json
  ```
  These will take a few minutes to run. They are building from the AWS Marketplace CentOS 7 AMIs.

- Once your images are built, do the following:
  - **If you built images, note the AMI id that resulted from the consul server build** and update the `ami` lookup selector in your `variables.tf` file:
    ```
    // Add AMI id here to build a consul cluster with
    // consul installed and puppet boostrapped
    variable "server_ami" {
      default = {
        us-east-1-centos7 = "ami-mysweetserver"
      }
    }
    ```
  - **If you built images, copy and paste the AMI id that resulted from the consul client build** and update the `client_ami` lookup selector in your `variables.tf` file:
    ```
    // Add AMI ID here to build hosts with puppet and
    // consul agent bootstrapped
    variable "client_ami" {
      default = "ami-mysweetclient"
    }
    ```
- Now let's get rolling.
- **Change directories into the root of the repository.**
  ```
  $ cd /path/to/consul-template-demo
  # Make sure you get any necessary modules
  $ terraform get
  ```
  - **Choose an arbitrary, unique key name (one that doesn't already exist in your AWS account). Specify it when prompted when you run `terraform plan` and `terraform apply`.

  Terraform will create this deploy key for you based on the key contents you provide.

  As an alternative to specifying the key when you run `terraform apply`, you can add it to your terraform.tfvars file, your workspace variables in Terraform Enterprise, or you can export it as an environment variable. The first and third options are detailed below.**
  ```
  $ export TF_VAR_key_name='chad-consul'
  # OR
  $ vi terraform.tfvars
  # Add the below line without a comment:
  # key_name = "chad-consul"
  ```

- **Set your variables as environment variables, in a terraform.tfvars file or in your Terraform Enterprise workspace.**
```
export TF_VAR_key_name=chad-consul
export TF_VAR_cluster_name="chad_dev"
export TF_VAR_private_key="$(cat /path/to/private_key.pem)"
export TF_VAR_public_key="$(cat /path/to/consul.pub)"
```
- **Let's make sure the consul cluster and web application are ready to build.**  Run the below to make sure the cluster will build correctly (note that you'll need to tell Terraform where your `credentials` file is if you didn't place it in `~/.aws`.):
  ```
  $ terraform plan
  ```
  **Tip:**  You can change the `count` parameter in either `consul_cluster.tf` or `web_app.tf` if you want more consul server or web app nodes, respectively.
- If it all looks good, **let's build it.**
  ```
  $ terraform apply
  ```
  This will take a few minutes.  Grab a coffee, knit, or do whatever you're into.
- When the build is done, **Terraform will tell you all the addresses you need to test things out.**
  ```
  Outputs:

  consul_server_address = ec2-52-3-120-224.compute-1.amazonaws.com
  haproxy_address = ec2-52-200-152-252.compute-1.amazonaws.com
  web_0_address = ec2-54-172-256-210.compute-1.amazonaws.com
  web_1_address = ec2-34-217-109-151.compute-1.amazonaws.com
  ```
  Note:  Your addresses will be different than the above, of course.  The below are just examples.
- **Access the web application** by navigating in a browser to the `haproxy_address`.
  ```
  http://ec2-52-200-152-252.compute-1.amazonaws.com
  ```
  - As you refresh, you'll be alternating between the web hosts (round robin load balancing).
  - The nodes are each **showing you information about the active members of the cluster.**
  - **Consul Template is updating both HAProxy's configs and the web hosts' `index.html`** files dynamically and in real time as things change.
- **Access the Consul server** if you're curious about the `web` service and other checks.
  ```
  http://ec2-52-3-120-224.compute-1.amazonaws.com/8500/ui
  ```
- **Log into one of the web nodes and stop/start apache.**  Refresh the HAProxy address in your browser and watch the nodes drop out and come back into the cluster.
  ```
  $ ssh -i /path/to/mykey.pem centos@ec2-54-172-256-210.compute-1.amazonaws.com
  $ systemctl stop|start httpd
  ```
  - As you start and stop the service, refresh your browser page and watch the members of the web service refresh.
    - This is the result of consul-template watching the web service members and doing the following when the members change:
      - Updating the HAProxy config and reloading the HAProxy Service
      - Updating the index.html page on each web node
  - Notice that each web host displays its hostname at the bottom of the page so that you know which web host is serving your request.


- **Check out service status in the Consul UI.**
  ```
  http://ec2-35-170-248-157.compute-1.amazonaws.com:8500
  ```

- **Examine the consul-template configuration files.**
  - The [HAProxy template file](config/haproxy/haproxy.cfg.tpl)
  - The [consul web service registry configuration files](config/web/web.json). [consul-template](config/consul-template/consul-template.d/consul-template.json) config file.
  - The [index.html template file](config/httpd/index.html.tpl)
  - You can also inspect them on the hosts.
  ```
  $ ssh -i /path/to/mykey.pem centos@ec2-54-172-256-210.compute-1.amazonaws.com
  $ cd /etc/consul-template.d
  $ cd /etc/consul
  $ cd /var/www/html
  $ cd /tmp
  ```

## Summary
In this demo, you did the following:
- Successfully deployed five web service nodes, three Consul servers and an HAProxy node.
  - Each web host registers its web service automatically to the Consul cluster.
  - Consul-template watches the web service.
  - If there are changes, consul-template updates the HAProxy config and reloads the service in addition to updating the index.html file on each web host, adding or removing new or dead web service members.

This is a simple example of how consul-template can make powerful changes in a completely automatic, nearly real-time cadence without refactoring your applications.

### Tools used in this demo:
- Packer
- Terraform
- AWS
- CentOS 7
- Consul
- Consul Template
- Systemd
- HAProxy
- HTML
