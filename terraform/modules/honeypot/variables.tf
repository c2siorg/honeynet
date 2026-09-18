variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for honeypot instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for honeypot nodes."
  type        = string
  default     = "t3.micro"
}

variable "log_sink_bucket_arn" {
  description = "ARN of the S3 bucket that receives raw honeypot logs."
  type        = string
}
