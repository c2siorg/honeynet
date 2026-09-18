variable "prefix" {
  description = "Prefix for all resources created by this module."
  type        = string
  default     = "honeynet-gcp"
}

variable "gcp_region" {
  description = "The GCP region to deploy the honeypot into."
  type        = string
  default     = "us-central1"
}

variable "machine_type" {
  description = "The GCP compute instance machine type."
  type        = string
  default     = "e2-micro"
}

variable "allowed_bait_ports" {
  description = "List of TCP ports to expose to the public internet for attackers to hit."
  type        = list(string)
  default     = ["22", "2222", "23", "80"]
}