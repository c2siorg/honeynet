variable "aws_region" {
  description = "AWS region where the state bucket and lock table will be created."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state."
  type        = string
  default     = "honeynet-tfstate-global"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "honeynet-tfstate-lock"
}