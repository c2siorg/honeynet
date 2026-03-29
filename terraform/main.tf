module "honeypot_region" {
  source = "./modules/honeypot_region"

  for_each = var.regions

  project_name    = var.project_name
  region          = each.key
  cloud_provider  = each.value.cloud_provider
  honeypot_type   = each.value.honeypot_type
  instance_count  = each.value.instance_count
  additional_tags = each.value.tags
}
