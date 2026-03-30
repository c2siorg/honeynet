provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "honeynet-platform"
      ManagedBy   = "terraform"
      Environment = "development"
    }
  }
}