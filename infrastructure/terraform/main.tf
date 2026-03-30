terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# Call the VM module
module "honeypot_vm" {
  source = "./modules/vm"
  
  instance_type = var.instance_type
  ami_id       = var.ami_id
  key_name     = var.key_name
  subnet_id    = var.subnet_id
  
  tags = {
    Name        = "honeynet-platform-initial"
    Project     = "honeynet-platform"
    Environment = "development"
    Purpose     = "initial-setup"
  }
}