output "log_sink_bucket" {
  description = "Name of the S3 bucket receiving raw honeypot logs."
  value       = aws_s3_bucket.log_sink.bucket
}

output "log_sink_arn" {
  description = "ARN of the raw log sink S3 bucket."
  value       = aws_s3_bucket.log_sink.arn
}

output "enriched_logs_bucket" {
  description = "Name of the S3 bucket storing enriched attack logs."
  value       = aws_s3_bucket.enriched_logs.bucket
}

output "lambda_function_name" {
  description = "Name of the IP enrichment Lambda function."
  value       = aws_lambda_function.enrichment.function_name
}

output "athena_workgroup" {
  description = "Athena workgroup name for querying attack data."
  value       = aws_athena_workgroup.honeynet.name
}

output "glue_database" {
  description = "Glue catalog database name."
  value       = aws_glue_catalog_database.honeynet.name
}

output "example_athena_queries" {
  description = "Example SQL queries to run in Athena."
  value = {
    top_attacking_ips   = "SELECT src_ip, COUNT(*) as attempts FROM ${aws_glue_catalog_database.honeynet.name}.enriched ORDER BY attempts DESC LIMIT 20;"
    high_abuse_scores   = "SELECT src_ip, abuse_score, country_code FROM ${aws_glue_catalog_database.honeynet.name}.enriched WHERE abuse_score > 80 ORDER BY abuse_score DESC;"
    attacks_by_country  = "SELECT country_code, COUNT(*) as attacks FROM ${aws_glue_catalog_database.honeynet.name}.enriched GROUP BY country_code ORDER BY attacks DESC;"
    credential_attempts = "SELECT username, password, COUNT(*) as tries FROM ${aws_glue_catalog_database.honeynet.name}.enriched WHERE eventid='cowrie.login.failed' GROUP BY username, password ORDER BY tries DESC LIMIT 20;"
  }
}