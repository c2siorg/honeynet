variable "name_prefix" {
  description = "Prefix applied to telemetry resource names."
  type        = string
  default     = "honeynet"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "production"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for honeypot instances."
  type        = string
  default     = "/mnt/c/Users/harir/.ssh/honeynet_key.pub"
}

variable "honeypot_instance_type" {
  description = "EC2 instance type used for honeypot nodes."
  type        = string
  default     = "t3.micro"
}

variable "telemetry_region" {
  description = "AWS region where the telemetry stack is deployed."
  type        = string
  default     = "us-east-1"
}

variable "abuseipdb_api_key" {
  description = "AbuseIPDB API key used by the telemetry Lambda enrichment function."
  type        = string
  sensitive   = true
}
