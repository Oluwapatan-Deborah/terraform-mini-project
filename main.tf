terraform {
  required_providers{
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
    }
  }
}

#Configure the aws provider
# provider "aws" {
# shared_credentials_file = "~/.aws/credentials"
# region = var.aws_region
# }


#vpc resource start
resource "aws_vpc" "miniproject_vpc" {
  cidr_block = var.cidr_block
  enable_dns_support = "true"
  enable_dns_hostnames ="true"
  enable_classiclink = "false"
  instance_tenancy = "default"
  tags = {
    Name = "miniproject_vpc"
  }

}

#public route table
resource "aws_route_table" "miniproject-public-route-table" {
    vpc_id = "${aws_vpc.miniproject_vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = "${aws_internet_gateway.miniproject_internet_gateway.id}" 
    }
    
    tags = {
        Name = "miniproject-public-route-table"
    }
}

# Public Subnet1
resource "aws_subnet" "miniproject-public-subnet1" {
  vpc_id                  = aws_vpc.miniproject_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "miniproject-public-subnet1"
  }
}
# Create Public Subnet-2
resource "aws_subnet" "miniproject-public-subnet2" {
  vpc_id                  = aws_vpc.miniproject_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "miniproject-public-subnet2"
  }
}


#Associating public subnet 1 with public route table
resource "aws_route_table_association" "miniproject-public-subnet1-association" {
  subnet_id      = aws_subnet.miniproject-public-subnet1.id
  route_table_id = aws_route_table.miniproject-public-route-table.id
}


# Associating public subnet 2 with public route table
resource "aws_route_table_association" "miniproject-public-subnet2-association" {
  subnet_id      = aws_subnet.miniproject-public-subnet2.id
  route_table_id = aws_route_table.miniproject-public-route-table.id
}


# internet gateway
resource "aws_internet_gateway" "miniproject_internet_gateway" {
  vpc_id = aws_vpc.miniproject_vpc.id

  tags = {
    Name = "miniproject_internet_gateway"
  }
}
#vpc resource end

#security group for load balancer
resource "aws_security_group" "miniproject-loadbalancer_sg" {
    vpc_id = "${aws_vpc.miniproject_vpc.id}"
    
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ssh-allowed"
    }
}

#security group for ec2 instances
resource "aws_security_group" "miniproject-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.miniproject_vpc.id
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.miniproject-loadbalancer_sg.id]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.miniproject-loadbalancer_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   
  }
  tags = {
    Name = "miniproject-security-grp-rule"
  }
}
#securitygroup end

resource "aws_instance" "miniproject1" {
  ami             = var.AMI
  instance_type   = "t2.micro"
  availability_zone = "us-east-1a"
  key_name        = "project"
  subnet_id       = aws_subnet.miniproject-public-subnet1.id
  security_groups = [aws_security_group.miniproject-security-grp-rule.id]
  tags = {
    Name   = "miniproject-1"
    source = "terraform"
  }
}
# creating instance 2
 resource "aws_instance" "miniproject2" {
  ami             = var.AMI
  instance_type   = "t2.micro"
  key_name        = "project"
  subnet_id       = aws_subnet.miniproject-public-subnet2.id
  security_groups = [aws_security_group.miniproject-security-grp-rule.id]
  availability_zone = "us-east-1b"
  tags = {
    Name   = "miniproject-2"
    source = "terraform"
  }
}
# creating instance 3
resource "aws_instance" "miniproject3" {
  ami             = var.AMI
  instance_type   = "t2.micro"
  key_name        = "project"
  security_groups = [aws_security_group.miniproject-security-grp-rule.id]
  subnet_id       = aws_subnet.miniproject-public-subnet2.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "miniproject-3"
    source = "terraform"
  }
}


resource "local_file" "Ip_address" {
  filename = "/vagrant/terraform/host-inventory"
  content  = <<EOT
${aws_instance.miniproject1.public_ip}
${aws_instance.miniproject2.public_ip}
${aws_instance.miniproject3.public_ip}
  EOT
}

resource "aws_lb" "miniproject-load-balancer" {
  name               = "miniproject-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.miniproject-loadbalancer_sg.id]
  subnets            = [aws_subnet.miniproject-public-subnet1.id, aws_subnet.miniproject-public-subnet2.id]
  enable_deletion_protection = false
  depends_on                 = [aws_instance.miniproject1, aws_instance.miniproject2, aws_instance.miniproject3]
}

resource "aws_lb_target_group" "miniproject-target-group" {
  name     = "miniproject-target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.miniproject_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# listener
resource "aws_lb_listener" "miniproject-listener" {
  load_balancer_arn = aws_lb.miniproject-load-balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:650753067696:certificate/047cf7e4-b67f-4310-a046-daffd30696dc"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.miniproject-target-group.arn
  }
}

# listener rule
resource "aws_lb_listener_rule" "miniproject-listener-rule" {
  listener_arn = aws_lb_listener.miniproject-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.miniproject-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# target group attached to the load balancer
resource "aws_lb_target_group_attachment" "miniproject-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.miniproject-target-group.arn
  target_id        = aws_instance.miniproject1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "miniproject-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.miniproject-target-group.arn
  target_id        = aws_instance.miniproject2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "miniproject-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.miniproject-target-group.arn
  target_id        = aws_instance.miniproject3.id
  port             = 80 
  
  }
  #instances end

#route53 start
  data "aws_route53_zone" "zone" {
  zone_id      = "Z014425328ESGSW9WHEDC"
  private_zone = false
}

resource "aws_route53_record" "site_domain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.miniproject-load-balancer.dns_name
    zone_id                = aws_lb.miniproject-load-balancer.zone_id
    evaluate_target_health = false
  }
}
#route53 end