# =============================================================================
# Honeynet — Remote State Bootstrap
#
# This configuration provisions the S3 bucket and DynamoDB table required
# to store and lock Terraform state remotely. It must be applied ONCE using
# local state before all other modules switch to the remote backend.
#
# Usage:
#   cd terraform/backend
#   terraform init
#   terraform apply
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# S3 Bucket — Terraform State Storage
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "tf_state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Project     = "honeynet"
    ManagedBy   = "terraform"
    Purpose     = "remote-state"
    Environment = "global"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ------------------------------------------------------------------------------
# DynamoDB Table — State Locking
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "tf_state_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project     = "honeynet"
    ManagedBy   = "terraform"
    Purpose     = "state-locking"
    Environment = "global"
  }
}