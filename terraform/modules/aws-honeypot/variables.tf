variable "name_prefix" {
  type = string
}

variable "region_label" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "admin_ssh_cidr" {
  type        = string
  description = "CIDR allowed for SSH to port 22 on the host (optional admin path)."
}

variable "key_name" {
  type    = string
  default = null
}

variable "honeypot_image" {
  type = string
}

variable "enable_flow_logs" {
  type = bool
}

variable "flow_logs_retention_days" {
  type = number
}
