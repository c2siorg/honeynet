variable "regions" {
  description = "AWS regions to deploy honeypot nodes into"
  type        = list(string)
  default     = ["us-east-1", "eu-west-1", "ap-southeast-1"]
}

variable "honeypot_type" {
  description = "Which honeypot to run: cowrie or dionaea"
  type        = string
  default     = "cowrie"
}

variable "instance_type" {
  description = "EC2 instance type for honeypot nodes"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
