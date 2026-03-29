variable "region" {
  type = string
}

variable "honeypot_type" {
  type    = string
  default = "cowrie"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "management_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
