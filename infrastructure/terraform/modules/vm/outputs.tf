output "public_ip" {
  description = "Public IP address of the VM"
  value       = aws_instance.honeypot.public_ip
}

output "instance_id" {
  description = "Instance ID of the created VM"
  value       = aws_instance.honeypot.id
}

output "private_ip" {
  description = "Private IP address of the VM"
  value       = aws_instance.honeypot.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.honeypot_sg.id
}
