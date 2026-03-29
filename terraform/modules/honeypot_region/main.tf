locals {
  merged_tags = merge(
    {
      project    = var.project_name
      region     = var.region
      provider   = var.cloud_provider
      honeypot   = var.honeypot_type
      managed_by = "terraform"
    },
    var.additional_tags
  )
}

# This resource stores deployment intent while cloud-specific resources are added incrementally.
resource "terraform_data" "deployment_intent" {
  input = {
    region         = var.region
    cloud_provider = var.cloud_provider
    honeypot_type  = var.honeypot_type
    instance_count = var.instance_count
    tags           = local.merged_tags
  }
}
