module "honeypot" {
  source = "./modules/aws-honeypot"

  name_prefix    = var.name_prefix
  region_label   = var.region_label
  instance_type  = var.instance_type
  admin_ssh_cidr = var.admin_ssh_cidr
  key_name       = var.key_name
  honeypot_image = var.honeypot_image

  enable_flow_logs           = var.enable_flow_logs
  flow_logs_retention_days   = var.flow_logs_retention_days
}
