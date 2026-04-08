terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}


provider "aws" {
  region = "eu-west-1"
}



################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "shopnaija-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true   # cost-effective for startup

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "shopnaija-vpc"
  }
}

################################################################################
# Output
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private App Subnet IDs"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Database Subnet IDs"
  value       = module.vpc.database_subnets
}