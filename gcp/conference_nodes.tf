# =============================================================================
# Transcoding Conference Node Instances
# =============================================================================

# Transcoding node instances
resource "google_compute_instance" "transcoding_nodes" {
  for_each = {
    for name, node in var.transcoding_nodes : name => merge(node, {
      name = coalesce(node.name, "${var.transcoding_node_name}-${name}")
    })
  }

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = local.transcoding_node_configs[each.key].tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pexip_infinity_image.self_link
      size  = each.value.disk_size
      type  = each.value.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.pexip_subnets[each.value.region].self_link

    # Configure public IP if enabled
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
      ssh-keys = local.ssh_public_key
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance.management_node,
    google_compute_firewall.protocol_rules,
    google_compute_firewall.service_rules
  ]
}

# Static public IPs for transcoding nodes (if enabled)
resource "google_compute_address" "transcoding_public_ips" {
  for_each = {
    for name, node in var.transcoding_nodes : name => node
    if node.public_ip
  }

  name         = coalesce(try(each.value.name, null), "${var.transcoding_node_name}-${each.key}")-ip
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# =============================================================================
# Proxy Conference Node Instances
# =============================================================================

# Proxy node instances
resource "google_compute_instance" "proxy_nodes" {
  for_each = {
    for name, node in var.proxy_nodes : name => merge(node, {
      name = coalesce(node.name, "${var.proxy_node_name}-${name}")
    })
  }

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = local.proxy_node_configs[each.key].tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pexip_infinity_image.self_link
      size  = each.value.disk_size
      type  = each.value.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.pexip_subnets[each.value.region].self_link

    # Configure public IP if enabled
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
      ssh-keys = local.ssh_public_key
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance.management_node,
    google_compute_firewall.protocol_rules,
    google_compute_firewall.service_rules
  ]
}

# Static public IPs for proxy nodes (if enabled)
resource "google_compute_address" "proxy_public_ips" {
  for_each = {
    for name, node in var.proxy_nodes : name => node
    if node.public_ip
  }

  name         = coalesce(try(each.value.name, null), "${var.proxy_node_name}-${each.key}")-ip
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
