# =============================================================================
# Transcoding Conference Node Instances
# =============================================================================

# Transcoding node instances
resource "google_compute_instance" "transcoding_nodes" {
  for_each = local.transcoding_nodes

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = local.transcoding_node_configs[each.key].tags

  boot_disk {
    initialize_params {
      image = google_compute_image.conf_image.self_link
      size  = each.value.disk_size
      type  = each.value.disk_type
    }
  }

  network_interface {
    subnetwork = var.regions[each.value.region].subnet_name

    dynamic "access_config" {
      for_each = each.value.public_ip ? [1] : []
      content {
        nat_ip = try(google_compute_address.transcoding_public_ips[each.key].address, null)
      }
    }
  }

  metadata = merge(
    local.transcoding_node_configs[each.key].metadata,
    {
      ssh-keys               = local.ssh_public_key
      block-project-ssh-keys = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance.management_node,
    google_compute_firewall.transcoding_media,
    google_compute_firewall.transcoding_services,
    google_compute_firewall.signaling,
    google_compute_firewall.internal,
    google_project_service.apis
  ]
}

# Static public IPs for transcoding nodes (if enabled)
resource "google_compute_address" "transcoding_public_ips" {
  for_each = {
    for name, node in local.transcoding_nodes : name => node
    if node.public_ip && node.static_ip
  }

  name         = "${each.value.name}-ip"
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# =============================================================================
# Proxy Conference Node Instances
# =============================================================================

# Proxy node instances
resource "google_compute_instance" "proxy_nodes" {
  for_each = local.proxy_nodes

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = local.proxy_node_configs[each.key].tags

  boot_disk {
    initialize_params {
      image = google_compute_image.conf_image.self_link
      size  = local.default_node_config.proxy.disk_size
      type  = local.default_node_config.proxy.disk_type
    }
  }

  network_interface {
    subnetwork = var.regions[each.value.region].subnet_name

    dynamic "access_config" {
      for_each = each.value.public_ip ? [1] : []
      content {
        nat_ip = try(google_compute_address.proxy_public_ips[each.key].address, null)
      }
    }
  }

  metadata = merge(
    local.proxy_node_configs[each.key].metadata,
    {
      ssh-keys               = local.ssh_public_key
      block-project-ssh-keys = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance.management_node,
    google_compute_firewall.proxy_media,
    google_compute_firewall.signaling,
    google_compute_firewall.internal
  ]
}

# Static public IPs for proxy nodes (if enabled)
resource "google_compute_address" "proxy_public_ips" {
  for_each = {
    for name, node in local.proxy_nodes : name => node
    if node.public_ip && node.static_ip
  }

  name         = "${each.value.name}-ip"
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
