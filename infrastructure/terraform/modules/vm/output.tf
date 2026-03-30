output "public_ip" {
  description = "Public IP address of the VM"
  value       = aws_instance.vm.public_ip
}
 
output "instance_id" {
  description = "Instance ID of the VM"
  value       = aws_instance.vm.id
}
 
output "honeypot_status" {
  description = "Status of Cowrie honeypot installation"
  value       = "Cowrie SSH honeypot installed on port 2222, Telnet on port 2223"
}
