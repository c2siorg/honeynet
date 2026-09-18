provider "aws" {
  region = var.telemetry_region
}

provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "ap"
  region = "ap-south-1"
}
