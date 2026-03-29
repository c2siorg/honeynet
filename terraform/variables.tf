variable "aws_region" {
  type        = string
  description = "AWS region for this stack (deploy one state per region for global coverage)."
}

variable "region_label" {
  type        = string
  description = "Short tag for this deployment (e.g. na, eu, apac) for resource naming and analytics."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names."
  default     = "honeynet"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the honeypot host."
  default     = "t3.small"
}

variable "admin_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH to the host on port 22 for administration (not the honeypot listener). Use a narrow range when key_name is set; default is loopback so Checkov does not treat open SSH as the default."
  default     = "127.0.0.1/32"
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair name for SSH access to the instance OS."
  default     = null
}

variable "honeypot_image" {
  type        = string
  description = "OCI image for the SSH honeypot container (Cowrie-compatible)."
  default     = "cowrie/cowrie:latest"
}

variable "enable_flow_logs" {
  type        = bool
  description = "Publish VPC flow logs to CloudWatch for enrichment and correlation."
  default     = true
}

variable "flow_logs_retention_days" {
  type        = number
  description = "CloudWatch Logs retention for flow logs."
  default     = 14
}
