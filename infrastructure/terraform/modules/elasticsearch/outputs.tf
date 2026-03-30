output "elasticsearch_endpoint" {
  description = "Elasticsearch endpoint URL"
  value       = "http://${aws_instance.elasticsearch.private_ip}:9200"
}

output "elasticsearch_private_ip" {
  description = "Private IP of Elasticsearch node"
  value       = aws_instance.elasticsearch.private_ip
}

output "elasticsearch_id" {
  description = "Instance ID of Elasticsearch"
  value       = aws_instance.elasticsearch.id
}
