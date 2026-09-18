output "honeywall_public_ip" {
  description = "Public IP address of Honeywall"
  value       = aws_instance.honeywall.public_ip
}

output "honeywall_private_ip" {
  description = "Private IP address of Honeywall"
  value       = aws_instance.honeywall.private_ip
}

output "honeywall_id" {
  description = "Instance ID of Honeywall"
  value       = aws_instance.honeywall.id
}

output "honeypot_backend_ip" {
  description = "Private IP of honeypot backend network"
  value       = aws_network_interface.honeypot_backend.private_ip
}
