terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # configure via backend.tfvars
    # bucket = "your-state-bucket"
    # key    = "honeynet/terraform.tfstate"
    # region = "us-east-1"
  }
}

module "honeypot_node" {
  for_each = toset(var.regions)

  source              = "./modules/honeypot-node"
  region              = each.key
  honeypot_type       = var.honeypot_type
  instance_type       = var.instance_type
  ssh_public_key_path = var.ssh_public_key_path
}

module "monitoring" {
  source       = "./modules/monitoring"
  honeypot_ips = [for node in module.honeypot_node : node.public_ip]
}
