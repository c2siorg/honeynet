variable "project_name" {
  description = "Project name used in metadata"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "cloud_provider" {
  description = "Target cloud provider (aws/azure/gcp)"
  type        = string
}

variable "honeypot_type" {
  description = "Honeypot profile type (ssh/http/cowrie/etc.)"
  type        = string
}

variable "instance_count" {
  description = "Number of honeypot instances for the region"
  type        = number
}

variable "additional_tags" {
  description = "Additional deployment tags"
  type        = map(string)
  default     = {}
}
