output "grafana_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
}
