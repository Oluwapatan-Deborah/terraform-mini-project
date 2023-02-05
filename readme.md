**Altschool mini project II (using Ansible and Terraform)**

Infrastructure as a code using terraform to setup 3 EC2 instances put behind a load balancer, integrated with ansible to provision the web servers.

**main.tf**
This terraform file contains blocks that do the following;
* Provider block

* Creates vpc

* Creates a public route table which contains existing routes to CIDR blocks outside of the ranges in our VPC.

* 2 public subnet  which is subnet that is associated with a route table that has a route to an internet gateway.

* A block associating the two public subnets with the public route table

* An Internet gateway which  allows communication between our VPC and the internet. 

* A security group for our loadbalancer with inbound and outbound rules.

* A security group for our 3 ec2 instances with inbound and outbound rules.

* A block each creating our 3 ec2 instances with an ubuntu AMI and t2.micro Instance type.

* A block creating a file to store our ip addresses (host-inventory).

* A block each creating our Application load balancer and target group.

* Listener e which checks for connection requests, using the protocol and port that configured and a Listener rule which are rules that is defined for a listener determine how the load balancer routes request to the targets in one or more target groups.

* Attaching our target group to each of the three instances craeted.

* A script which helps us set up a hosted zone with route 53.


**provider.tf**
This contain the provider block which was later specified in the main.tf file.


**var.tf**
This contains variables for terraform configuration

**output.tf**
This file prints out the output for our load balancer.



**ANSIBLE FILES**

**main.yml**
This contains the file used for setting up a web server in an EC2 instance, calls and runs the EC2 and deploys the ansible playbook on the EC2 instances.

**roles/setup/tasks(main.yml)**
This contains the tasks to install apache2 and ensure it is running , task to set timezone and print hostname and date on the server.

**host-inventory**
This is there file where our terraform stores our ip addresses after runnung terraform plan and apply.

