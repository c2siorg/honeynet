variable "ami_id" {
  description = "AMI ID for Logstash"
  type        = string
}

variable "instance_type" {
  description = "Instance type for Logstash"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Logstash"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "elasticsearch_hosts" {
  description = "Elasticsearch hosts"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
