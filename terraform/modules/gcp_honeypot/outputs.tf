output "honeypot_public_ip" {
  description = "The public IP address of the GCP honeypot instance."
  value       = google_compute_instance.honeypot_node.network_interface[0].access_config[0].nat_ip
}

output "honeypot_vpc_name" {
  description = "The name of the isolated VPC."
  value       = google_compute_network.honeypot_vpc.name
}

output "service_account_email" {
  description = "The email of the least-privilege service account attached to the VM."
  value       = google_service_account.honeypot_sa.email
}