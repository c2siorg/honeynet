output "state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state."
  value       = aws_s3_bucket.tf_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.tf_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.tf_state_lock.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB state lock table."
  value       = aws_dynamodb_table.tf_state_lock.arn
}

output "backend_config_snippet" {
  description = "Drop this block into any Terraform module's backend configuration."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tf_state.bucket}"
        key            = "<module-name>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.tf_state_lock.name}"
        encrypt        = true
      }
    }
  EOT
}