# =============================================================================
# Management Node Instance
# =============================================================================

resource "google_compute_instance" "management_node" {
  name = coalesce(
    try(var.mgmt_node.name, null),
    var.mgmt_node_name
  )
  machine_type = var.mgmt_node.machine_type
  zone         = var.mgmt_node.zone

  tags = local.mgmt_node_config.tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pexip_infinity_image.self_link
      size  = var.mgmt_node.disk_size
      type  = var.mgmt_node.disk_type
    }
  }

  network_interface {
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
      ssh-keys = local.ssh_public_key
      management_node_config = jsonencode({
        hostname         = var.mgmt_node.hostname
        domain           = var.mgmt_node.domain
        ip               = google_compute_address.mgmt_internal_ip.address
        mask             = cidrnetmask(var.mgmt_node.subnet_cidr)
        gw               = var.mgmt_node.gateway_ip
        dns              = join(",", local.system_configs.dns_config.servers)
        ntp              = join(",", local.system_configs.ntp_config.servers)
        user             = var.mgmt_node.admin_username
        pass             = var.mgmt_node.admin_password_hash
        os_pass          = var.mgmt_node.os_password_hash
      })
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.pexip_infinity_network,
    google_compute_subnetwork.pexip_subnets,
    google_compute_firewall.allow_management
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
