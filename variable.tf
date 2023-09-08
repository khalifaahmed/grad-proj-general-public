variable "vpc_cidr" {
  type = string
}
variable "name" {
  type = string
}

variable "access_ip_v4" {
  type = string
}

variable "access_ip_v6" {
  type = string
}

variable "db_subnet_group" {
  type = bool
}

variable "db_instance" {
  type = bool
}

variable "provider_region" {
  type        = string
  default     = ""
  description = "description"
}
variable "ec2_count" {
  type = number
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "key" {
  type        = string
  default     = ""
  description = "description"
}

locals {
  public_cidrs  = [for i in range(1, 255, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_cidrs = [for i in range(2, 255, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnet_count  = length(data.aws_availability_zones.available.names)
  private_subnet_count = length(data.aws_availability_zones.available.names)
  max_subnets = length(data.aws_availability_zones.available.names) * 5
}

locals {
  security_groups = {
    ssh = {
      name        = "grad-proj-ssh-sg"
      description = "security group for public access"
      ingress = {
        ssh = {
          description      = "allow ssh from our access ip only"
          from             = 22
          to               = 22
          protocol         = "tcp"
          cidr_blocks      = [var.access_ip_v4]
          ipv6_cidr_blocks = [var.access_ip_v6]
        }
      }
    }
    http_https = {
      name        = "grad-proj-http-https-sg"
      description = "security group for public access"
      ingress = {
        http = {
          description      = "allow http traffic from anywhere"
          from             = 80
          to               = 80
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = ["::/0"]
        }
        https = {
          description      = "allow https traffic from anywhere"
          from             = 443
          to               = 443
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = ["::/0"]
        }
      }
    }
    rds = {
      name        = "grad-proj-rds-sg"
      description = "security group for rds"
      ingress = {
        postgres = {
          description      = "allow postgres sql traffic"
          from             = 5432
          to               = 5432
          protocol         = "tcp"
          cidr_blocks      = [var.access_ip_v4]
          ipv6_cidr_blocks = [var.access_ip_v6]
        }
      }
    }
    public = {
      name        = "grad-proj-public-sg"
      description = "security group for public access"
      ingress = {
        public = {
          description      = "allow all traffic from our access ip only"
          from             = 0
          to               = 0
          protocol         = "-1"
          cidr_blocks      = [var.access_ip_v4]
          ipv6_cidr_blocks = [var.access_ip_v6]
        }
      } 
    }   
  }
}

