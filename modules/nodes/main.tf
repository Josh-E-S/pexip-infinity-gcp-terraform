# =============================================================================
# Node SSH Key
# =============================================================================

# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "ssh_private_key" {
  depends_on = [var.apis]
  secret_id  = "${var.project_id}-pexip-${var.type}-ssh-key"

  replication {
    auto {}
  }

  labels = {
    terraform = "true"
    module    = "pexip"
    type      = var.type
  }
}

# Store the private key value
resource "google_secret_manager_secret_version" "ssh_private_key" {
  secret      = google_secret_manager_secret.ssh_private_key.id
  secret_data = tls_private_key.ssh.private_key_pem
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
  name         = local.instance_count > 1 ? "${var.name}-${count.index + 1}" : var.name
  machine_type = local.machine_type
  zone         = "${var.region}-b" # Default to zone b

  tags = local.network_tags

  boot_disk {
    initialize_params {
      image = var.image_name
      size  = local.boot_disk_size
      type  = "pd-ssd"  # Always use SSD for Pexip nodes
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
    ssh-keys               = "admin:${tls_private_key.ssh.public_key_openssh}"
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

# =============================================================================
# Static IP Addresses (if needed for future use)
# =============================================================================

# Could add static IP resources here if needed in the future
