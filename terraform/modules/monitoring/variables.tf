variable "honeypot_ips" {
  description = "IPs of honeypot nodes for Prometheus to scrape"
  type        = list(string)
}
