# Transcoding Conference Node instances
resource "google_compute_instance" "transcoding_nodes" {
  for_each = {
    for pair in flatten([
      for region, config in var.regions : [
        for idx in range(config.conference_nodes.transcoding.count) : {
          region = region
          index  = idx
          config = config
          zone   = config.conference_nodes.transcoding.zones[idx % length(config.conference_nodes.transcoding.zones)]
        }
      ]
    ]) : "${pair.region}-transcoding-${pair.index}" => pair
  }

  name         = "${var.conference_node_name}-trans-${each.key}"
  machine_type = try(each.value.config.conference_nodes.transcoding.config.machine_type, var.instance_configs.conference_transcoding.machine_type)
  zone         = each.value.zone

  tags = var.instance_configs.conference_transcoding.tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pexip_infinity_image.self_link
      size  = try(each.value.config.conference_nodes.transcoding.config.disk_size, var.instance_configs.conference_transcoding.disk_size)
      type  = var.instance_configs.conference_transcoding.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.pexip_subnets[each.value.region].self_link
    dynamic "access_config" {
      for_each = var.network_config.enable_public_ips ? [1] : []
      content {}
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance.management_node
  ]
}

# Proxy Conference Node instances (optional)
resource "google_compute_instance" "proxy_nodes" {
  for_each = {
    for pair in flatten([
      for region, config in var.regions : [
        for idx in range(try(config.conference_nodes.proxy.count, 0)) : {
          region = region
          index  = idx
          config = config
          zone   = try(config.conference_nodes.proxy.zones[idx % length(config.conference_nodes.proxy.zones)], "")
        }
      ] if try(config.conference_nodes.proxy, null) != null
    ]) : "${pair.region}-proxy-${pair.index}" => pair
  }

  name         = "${var.conference_node_name}-proxy-${each.key}"
  machine_type = try(each.value.config.conference_nodes.proxy.config.machine_type, var.instance_configs.conference_proxy.machine_type)
  zone         = each.value.zone

  tags = var.instance_configs.conference_proxy.tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pexip_infinity_image.self_link
      size  = try(each.value.config.conference_nodes.proxy.config.disk_size, var.instance_configs.conference_proxy.disk_size)
      type  = var.instance_configs.conference_proxy.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.pexip_subnets[each.value.region].self_link
    dynamic "access_config" {
      for_each = var.network_config.enable_public_ips ? [1] : []
      content {}
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance.management_node
  ]
}
