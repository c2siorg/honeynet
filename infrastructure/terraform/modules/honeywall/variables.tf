variable "ami_id" {
  description = "AMI ID for Honeywall"
  type        = string
}

variable "instance_type" {
  description = "Instance type for Honeywall"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Honeywall"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "honeypot_instance_id" {
  description = "Instance ID of honeypot to protect"
  type        = string
}

variable "honeypot_private_ip" {
  description = "Private IP of honeypot instance"
  type        = string
}

variable "elasticsearch_endpoint" {
  description = "Elasticsearch endpoint for logging"
  type        = string
}

variable "logstash_endpoint" {
  description = "Logstash endpoint for log shipping"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
