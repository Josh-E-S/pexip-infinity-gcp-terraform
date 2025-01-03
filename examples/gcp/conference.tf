# Conference Node Instances
resource "google_compute_instance" "pexip_conf_nodes" {
  for_each = {
    for idx in flatten([
      for region, count in var.conf_node_count : [
        for i in range(count) : {
          region = region
          index  = i
          zone   = var.zones[region][0]
        }
      ]
    ]) : "${idx.region}-${idx.index}" => idx
  }

  name         = "${var.conf_node_name}-${each.value.region}-${each.value.index + 1}"
  machine_type = var.conf_machine_type
  zone         = each.value.zone

  tags = ["pexip-conf-node", "pexip-provisioning"]

  boot_disk {
    initialize_params {
      image = google_compute_image.pexip_conf_image.id
      size  = var.conf_node_disk_size
      type  = var.conf_node_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.pexip_infinity_network.name
    subnetwork = google_compute_subnetwork.pexip_subnets[each.value.region].name
    network_ip = google_compute_address.conf_internal_ips[each.key].address

    dynamic "access_config" {
      for_each = var.enable_public_ips ? [1] : []
      content {
        nat_ip = google_compute_address.conf_external_ips[each.key].address
      }
    }
  }

  metadata = {
    ssh-keys = "admin:${var.ssh_public_key}"
  }

  # We recommend setting a minimum CPU platform for consistent performance
  min_cpu_platform = "Intel Cascade Lake"

  # Allow instance to be stopped for updates
  allow_stopping_for_update = true

  labels = merge(var.labels, {
    environment = var.environment
    managed-by  = "terraform"
    role        = "conference"
    region      = each.value.region
  })

  depends_on = [
    google_compute_instance.pexip_mgmt,
    null_resource.image_creation_check
  ]
}

# Output for Conference Node details
output "conference_nodes" {
  description = "Details of deployed Conference Nodes"
  value = {
    for node in google_compute_instance.pexip_conf_nodes :
    node.name => {
      internal_ip = node.network_interface[0].network_ip
      external_ip = var.enable_public_ips ? node.network_interface[0].access_config[0].nat_ip : "No external IP assigned"
      region      = split("-", node.zone)[0]
      zone        = node.zone
    }
  }
}
