variable "ami_id" {
  description = "AMI ID for honeypot instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for honeypot"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for honeypot"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block for SSH access"
  type        = string
}

variable "elasticsearch_endpoint" {
  description = "Elasticsearch endpoint"
  type        = string
}

variable "kibana_endpoint" {
  description = "Kibana endpoint"
  type        = string
}

variable "honeypot_count" {
  description = "Number of honeypot instances"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
