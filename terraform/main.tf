module "honeypots" {
  source = "./modules/honeypot"

  providers = {
    aws.us = aws.us
    aws.eu = aws.eu
    aws.ap = aws.ap
  }

  ssh_public_key_path = var.ssh_public_key_path
  instance_type       = var.honeypot_instance_type
  log_sink_bucket_arn = module.telemetry.log_sink_arn
}

module "telemetry" {
  source = "./modules/telemetry"

  name_prefix       = var.name_prefix
  aws_region        = var.telemetry_region
  environment       = var.environment
  abuseipdb_api_key = var.abuseipdb_api_key
}

output "honeypots" {
  value = module.honeypots.honeypots
}

output "telemetry_log_sink_bucket" {
  value = module.telemetry.log_sink_bucket
}

output "telemetry_enriched_logs_bucket" {
  value = module.telemetry.enriched_logs_bucket
}

output "telemetry_glue_database" {
  value = module.telemetry.glue_database
}

output "telemetry_athena_workgroup" {
  value = module.telemetry.athena_workgroup
}

output "telemetry_region" {
  value = var.telemetry_region
}
