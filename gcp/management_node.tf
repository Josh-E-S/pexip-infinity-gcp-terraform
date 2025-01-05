# Management Node Instance
resource "google_compute_instance" "management_node" {
  name         = var.mgmt_node_name
  machine_type = var.instance_configs.management.machine_type
  zone         = "${local.primary_region}-${var.regions[local.primary_region].conference_nodes.transcoding.zones[0]}"

  tags = var.instance_configs.management.tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pexip_infinity_image.self_link
      size  = var.instance_configs.management.disk_size
      type  = var.instance_configs.management.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.pexip_subnets[local.primary_region].self_link
    
    # Static internal IP configuration
    network_ip = google_compute_address.mgmt_node_internal_ip.address

    dynamic "access_config" {
      for_each = var.network_config.enable_public_ips ? [1] : []
      content {
        nat_ip = try(google_compute_address.mgmt_node_external_ip[0].address, null)
      }
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
    startup-script = templatefile("${path.module}/templates/management_node_startup.tpl", {
      admin_password_hash = var.mgmt_node_admin_password_hash
      os_password_hash   = var.mgmt_node_os_password_hash
      hostname          = var.mgmt_node_hostname
      domain           = var.mgmt_node_domain
    })
  }

  # Ensure management node is replaced rather than updated in-place
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.pexip_infinity_network,
    google_compute_subnetwork.pexip_subnets,
    google_compute_firewall.allow_management
  ]
}

# Static Internal IP for Management Node
resource "google_compute_address" "mgmt_node_internal_ip" {
  name         = "${var.mgmt_node_name}-internal-ip"
  subnetwork   = google_compute_subnetwork.pexip_subnets[local.primary_region].id
  address_type = "INTERNAL"
  region       = local.primary_region
}

# Static External IP for Management Node (if public IPs are enabled)
resource "google_compute_address" "mgmt_node_external_ip" {
  count        = var.network_config.enable_public_ips ? 1 : 0
  name         = "${var.mgmt_node_name}-external-ip"
  region       = local.primary_region
  address_type = "EXTERNAL"
}
