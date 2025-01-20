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
# Local Variables
# =============================================================================
locals {
  mgmt_node_config = {
    tags = [var.mgmt_node_name]
    metadata = {
      node_type = "management"
      node_name = coalesce(try(var.mgmt_node.name, null), var.mgmt_node_name)
      region    = var.mgmt_node.region
      zone      = var.mgmt_node.zone
    }
  }
  ssh_public_key = var.ssh_public_key
}

# =============================================================================
# Management Node Instance
# =============================================================================
resource "google_compute_instance" "management_node" {
  depends_on = [var.apis]
  name = coalesce(
    try(var.mgmt_node.name, null),
    var.mgmt_node_name
  )
  machine_type = var.mgmt_node.machine_type
  zone         = var.mgmt_node.zone

  tags = local.mgmt_node_config.tags

  boot_disk {
    initialize_params {
      image = var.mgmt_image.self_link
      size  = var.mgmt_node.disk_size
      type  = var.mgmt_node.disk_type
    }
  }

  network_interface {
    network    = var.network.name
    subnetwork = var.regions[var.mgmt_node.region].subnet_name

    # Static internal IP configuration
    network_ip = google_compute_address.mgmt_internal_ip.address

    # Configure public IP if enabled
    dynamic "access_config" {
      for_each = var.mgmt_node.public_ip ? [1] : []
      content {
        nat_ip = try(google_compute_address.mgmt_external_ip[0].address, null)
      }
    }
  }

  metadata = merge(
    local.mgmt_node_config.metadata,
    {
      ssh-keys               = local.ssh_public_key
      block-project-ssh-keys = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Management Node IP Addresses
# =============================================================================

# Static internal IP for management node
resource "google_compute_address" "mgmt_internal_ip" {
  depends_on   = [var.apis]
  name         = "${var.mgmt_node_name}-internal"
  subnetwork   = var.regions[var.mgmt_node.region].subnet_name
  address_type = "INTERNAL"
  region       = var.mgmt_node.region
}

# Static external IP for management node (if enabled)
resource "google_compute_address" "mgmt_external_ip" {
  depends_on   = [var.apis]
  count        = var.mgmt_node.public_ip ? 1 : 0
  name         = "${var.mgmt_node_name}-external"
  address_type = "EXTERNAL"
  region       = var.mgmt_node.region
  network_tier = "PREMIUM"
}
