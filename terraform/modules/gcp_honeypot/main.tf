# Dedicated VPC for the Honeypot to isolate it from other project resources
resource "google_compute_network" "honeypot_vpc" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "honeypot_subnet" {
  name          = "${var.prefix}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.honeypot_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_1_MIN"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Strict Firewall Rules: Allow ONLY specific bait ports (e.g., SSH, Telnet)
resource "google_compute_firewall" "allow_bait_ports" {
  name    = "${var.prefix}-allow-bait"
  network = google_compute_network.honeypot_vpc.name

  allow {
    protocol = "tcp"
    ports    = var.allowed_bait_ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["honeypot-node"]
}

# Dedicated least-privilege Service Account for the VM
resource "google_service_account" "honeypot_sa" {
  account_id   = "${var.prefix}-sa"
  display_name = "Honeypot Node Service Account"
}

# The actual Honeypot Compute Instance
resource "google_compute_instance" "honeypot_node" {
  name         = "${var.prefix}-node"
  machine_type = var.machine_type
  zone         = "${var.gcp_region}-a"
  tags         = ["honeypot-node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = google_compute_network.honeypot_vpc.name
    subnetwork = google_compute_subnetwork.honeypot_subnet.name
    access_config {
      # Ephemeral public IP to expose the honeypot
    }
  }

  # Shielded VM settings to prevent rootkit persistence
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = google_service_account.honeypot_sa.email
    scopes = ["cloud-platform"]
  }
}