variable "project_name" {
  description = "Project name used for metadata labeling"
  type        = string
  default     = "honeynet"
}

variable "regions" {
  description = "Map of regions and honeypot configuration"
  type = map(object({
    cloud_provider = string
    honeypot_type  = string
    instance_count = number
    tags           = map(string)
  }))
}
