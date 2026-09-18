variable "ami_id" {
  description = "AMI ID for pipeline instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for pipeline controller"
  type        = string
  default     = "t3.medium"
}

variable "low_interaction_instance_type" {
  description = "Instance type for low-interaction honeypots"
  type        = string
  default     = "t3.micro"
}

variable "high_interaction_instance_type" {
  description = "Instance type for high-interaction honeypots"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for deployment"
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

variable "allowed_api_cidr" {
  description = "CIDR block for API access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "low_interaction_count" {
  description = "Number of low-interaction honeypots"
  type        = number
  default     = 5
}

variable "high_interaction_count" {
  description = "Number of high-interaction honeypots"
  type        = number
  default     = 0  # On-demand only
}

variable "elasticsearch_endpoint" {
  description = "Elasticsearch endpoint for logging"
  type        = string
}

variable "kafka_endpoint" {
  description = "Kafka endpoint for event streaming"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint for caching"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
