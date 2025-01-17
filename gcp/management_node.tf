# =============================================================================
# Management Node Instance
# =============================================================================

resource "google_compute_instance" "management_node" {
  name = coalesce(
    try(var.mgmt_node.name, null),
    var.mgmt_node_name
  )
  machine_type = local.mgmt_node.machine_type
  zone         = var.mgmt_node.zone

  tags = local.mgmt_node_config.tags

  boot_disk {
    initialize_params {
      image = google_compute_image.mgmt_image.self_link
      size  = local.mgmt_node.disk_size
      type  = local.mgmt_node.disk_type
    }
  }

  network_interface {
    network    = data.google_compute_network.network.name
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

  metadata = {
    ssh-keys = local.ssh_public_key
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_image.mgmt_image,
    data.google_compute_network.network,
    google_project_service.apis
  ]
}

# =============================================================================
# Management Node IP Addresses
# =============================================================================

# Static internal IP for management node
resource "google_compute_address" "mgmt_internal_ip" {
  name         = "${var.mgmt_node_name}-internal"
  subnetwork   = var.regions[var.mgmt_node.region].subnet_name
  address_type = "INTERNAL"
  region       = var.mgmt_node.region
}

# Static external IP for management node (if enabled)
resource "google_compute_address" "mgmt_external_ip" {
  count        = var.mgmt_node.public_ip ? 1 : 0
  name         = "${var.mgmt_node_name}-external"
  address_type = "EXTERNAL"
  region       = var.mgmt_node.region
  network_tier = "PREMIUM"
}
