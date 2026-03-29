output "honeypot_ips" {
  description = "Public IPs of deployed honeypot nodes by region"
  value       = { for region, node in module.honeypot_node : region => node.public_ip }
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = module.monitoring.grafana_url
}
