variable "name_prefix" {
  description = "Prefix applied to all resource names. Must be lowercase alphanumeric and hyphens."
  type        = string
  default     = "honeynet"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name_prefix))
    error_message = "name_prefix must be lowercase alphanumeric/hyphens, start with a letter, max 20 chars."
  }
}

variable "aws_region" {
  description = "AWS region where the telemetry pipeline will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "production"
}

variable "abuseipdb_api_key" {
  description = "AbuseIPDB API key for threat intelligence enrichment. Get a free key at https://www.abuseipdb.com"
  type        = string
  sensitive   = true
}