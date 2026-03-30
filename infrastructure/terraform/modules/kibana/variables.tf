variable "ami_id" {
  description = "AMI ID for Kibana"
  type        = string
}

variable "instance_type" {
  description = "Instance type for Kibana"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Kibana"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR block for Kibana access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
