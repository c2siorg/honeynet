output "public_ip" {
  description = "Public IP address of the honeypot VM"
  value       = module.honeypot_vm.public_ip
}

output "instance_id" {
  description = "Instance ID of the created VM"
  value       = module.honeypot_vm.instance_id
}

output "ssh_connection_command" {
  description = "Command to connect via SSH"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.honeypot_vm.public_ip}"
}