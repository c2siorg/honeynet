output "deployment_metadata" {
  description = "Normalized metadata emitted for this regional deployment"
  value = {
    id             = terraform_data.deployment_intent.id
    region         = var.region
    cloud_provider = var.cloud_provider
    honeypot_type  = var.honeypot_type
    instance_count = var.instance_count
    tags           = local.merged_tags
  }
}
