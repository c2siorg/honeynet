output "region" {
  description = "AWS region for this deployment."
  value       = var.aws_region
}

output "honeypot_public_ip" {
  description = "Public IPv4 of the honeypot (sensor ingress)."
  value       = module.honeypot.public_ip
}

output "honeypot_instance_id" {
  description = "EC2 instance ID."
  value       = module.honeypot.instance_id
}

output "vpc_id" {
  description = "Isolated VPC ID for this honeypot."
  value       = module.honeypot.vpc_id
}

output "flow_log_group_name" {
  description = "CloudWatch log group for VPC flow logs, if enabled."
  value       = module.honeypot.flow_log_group_name
}
