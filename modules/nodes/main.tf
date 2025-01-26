# =============================================================================
# Nodes Module
# =============================================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# =============================================================================
# Node IP Addresses
# =============================================================================

# Static internal IP addresses
resource "google_compute_address" "internal_ip" {
  count        = local.instance_count
  name         = local.instance_count > 1 ? "${var.name}-internal-${count.index + 1}" : "${var.name}-internal"
  region       = var.region
  subnetwork   = var.subnet_id
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
}

# Static external IP addresses (if public IP is enabled)
resource "google_compute_address" "external_ip" {
  count        = var.public_ip ? local.instance_count : 0
  name         = local.instance_count > 1 ? "${var.name}-external-${count.index + 1}" : "${var.name}-external"
  region       = var.region
  network_tier = "PREMIUM" # Always use premium for better performance
}

# =============================================================================
# Node Instances
# =============================================================================

# Create instances based on type and quantity
resource "google_compute_instance" "node" {
  count        = local.instance_count
  depends_on   = [var.apis]
  name         = local.instance_count > 1 ? "${var.name}-${var.region}-${count.index + 1}" : "${var.name}-${var.region}"
  machine_type = local.machine_type
  zone         = "${var.region}-b" # Default to zone b

  tags = local.network_tags

  boot_disk {
    initialize_params {
      image = var.image_name
      size  = local.boot_disk_size
      type  = "pd-ssd" # Always use SSD for Pexip nodes
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    network_ip = google_compute_address.internal_ip[count.index].address

    # Configure public IP if enabled
    dynamic "access_config" {
      for_each = var.public_ip ? [1] : []
      content {
        nat_ip = google_compute_address.external_ip[count.index].address
      }
    }
  }

  # SSH key configuration using generated key
  metadata = {
    ssh-keys               = "admin:${var.ssh_public_key}"
    block-project-ssh-keys = "true"
  }

  labels = local.labels

  # Use default compute service account
  service_account {
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
