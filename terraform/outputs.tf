output "regional_deployments" {
  description = "Deployment metadata keyed by region"
  value       = { for region, mod in module.honeypot_region : region => mod.deployment_metadata }
}
