variable "aws_region" {    
    default = "us-east-1"
}

variable "domain_name" {
  default    = "dioluwapatan.me"
  type        = string
  description = "Domain name"
}

variable "cidr_block" {
    default  = "10.0.0.0/16"
}

variable "AMI" {
    type = string
    default = "ami-00874d747dde814fa"
}