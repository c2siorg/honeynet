output "public_ip" {
  value       = aws_instance.honeypot.public_ip
  description = "Public IP for honeypot traffic (SSH honeypot on port 2222)."
}

output "instance_id" {
  value = aws_instance.honeypot.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "flow_log_group_name" {
  value       = try(aws_cloudwatch_log_group.flow[0].name, null)
  description = "CloudWatch log group for VPC flow logs."
}
