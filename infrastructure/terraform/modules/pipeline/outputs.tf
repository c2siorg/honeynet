output "pipeline_controller_ip" {
  description = "Public IP of pipeline controller"
  value       = aws_instance.pipeline_controller.public_ip
}

output "pipeline_controller_private_ip" {
  description = "Private IP of pipeline controller"
  value       = aws_instance.pipeline_controller.private_ip
}

output "low_interaction_honeypots" {
  description = "Public IPs of low-interaction honeypots"
  value       = aws_instance.low_interaction_honeypots[*].public_ip
}

output "high_interaction_honeypots" {
  description = "Private IPs of high-interaction honeypots"
  value       = aws_instance.high_interaction_honeypots[*].private_ip
}

output "pipeline_endpoint" {
  description = "Pipeline API endpoint"
  value       = "${aws_instance.pipeline_controller.public_ip}:8080"
}
