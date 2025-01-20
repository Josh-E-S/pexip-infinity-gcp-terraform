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
  # =============================================================================
  # Default Node Configurations
  # =============================================================================
  default_node_config = {
    transcoding = {
      machine_type = "n2-standard-4"
      disk_size    = 50
      disk_type    = "pd-standard"
    }
    proxy = {
      machine_type = "n2-standard-4"
      disk_size    = 50
      disk_type    = "pd-standard"
    }
  }

  # =============================================================================
  # Node Configurations
  # =============================================================================

  # Transcoding node configurations
  transcoding_nodes = merge(flatten([
    for pool_name, pool in var.transcoding_node_pools : [
      for i in range(pool.count) : {
        "${pool_name}-${pool.zone}-${format("%d", i + 1)}" = {
          name         = "${var.transcoding_node_name}-${pool_name}-${format("%d", i + 1)}"
          region       = pool.region
          zone         = pool.zone
          machine_type = pool.machine_type
          disk_size    = pool.disk_size
          disk_type    = pool.disk_type
          public_ip    = pool.public_ip
          static_ip    = pool.static_ip
        }
      }
    ]
  ])...)

  # Proxy node configurations
  proxy_nodes = merge(flatten([
    for pool_name, pool in var.proxy_node_pools : [
      for i in range(pool.count) : {
        "${pool_name}-${pool.zone}-${format("%d", i + 1)}" = {
          name         = "${var.proxy_node_name}-${pool_name}-${format("%d", i + 1)}"
          region       = pool.region
          zone         = pool.zone
          machine_type = "n2-standard-4"
          public_ip    = pool.public_ip
          static_ip    = pool.static_ip
        }
      }
    ]
  ])...)

  # Process transcoding node configurations
  transcoding_node_configs = {
    for name, node in local.transcoding_nodes : name => {
      tags = distinct(concat(
        [var.transcoding_node_name],
        [for protocol, enabled in var.transcoding_services.enable_protocols : "${var.transcoding_node_name}-${protocol}" if enabled]
      ))
      metadata = {
        node_type = "transcoding"
        node_name = node.name
        region    = node.region
        zone      = node.zone
      }
    }
  }

  # Process proxy node configurations
  proxy_node_configs = {
    for name, node in local.proxy_nodes : name => {
      tags = distinct(concat(
        [var.proxy_node_name],
        [for protocol, enabled in var.proxy_services.enable_protocols : "${var.proxy_node_name}-${protocol}" if enabled]
      ))
      metadata = {
        node_type = "proxy"
        node_name = node.name
        region    = node.region
        zone      = node.zone
      }
    }
  }
}

# =============================================================================
# Transcoding Conference Node Instances
# =============================================================================

# Transcoding node instances
resource "google_compute_instance" "transcoding_nodes" {
  for_each   = local.transcoding_nodes
  depends_on = [var.apis, var.management_node]

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = local.transcoding_node_configs[each.key].tags

  boot_disk {
    initialize_params {
      image = var.conf_image.self_link
      size  = each.value.disk_size
      type  = each.value.disk_type
    }
  }

  network_interface {
    network    = var.network.name
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
      ssh-keys               = var.ssh_public_key
      block-project-ssh-keys = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Static public IPs for transcoding nodes (if enabled)
resource "google_compute_address" "transcoding_public_ips" {
  for_each = {
    for name, node in local.transcoding_nodes : name => node
    if node.public_ip && node.static_ip
  }
  depends_on = [var.apis]

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
  for_each   = local.proxy_nodes
  depends_on = [var.apis, var.management_node]

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone

  tags = local.proxy_node_configs[each.key].tags

  boot_disk {
    initialize_params {
      image = var.conf_image.self_link
      size  = local.default_node_config.proxy.disk_size
      type  = local.default_node_config.proxy.disk_type
    }
  }

  network_interface {
    network    = var.network.name
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
      ssh-keys               = var.ssh_public_key
      block-project-ssh-keys = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Static public IPs for proxy nodes (if enabled)
resource "google_compute_address" "proxy_public_ips" {
  for_each = {
    for name, node in local.proxy_nodes : name => node
    if node.public_ip && node.static_ip
  }
  depends_on = [var.apis]

  name         = "${each.value.name}-ip"
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
