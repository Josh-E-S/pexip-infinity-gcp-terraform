# Management Node Instance
resource "google_compute_instance" "pexip_mgmt" {
  name         = var.mgmt_node_name
  machine_type = var.mgmt_machine_type
  zone         = var.zones[var.default_region][0]

  tags = ["pexip-management"]

  boot_disk {
    initialize_params {
      image = google_compute_image.pexip_mgmt_image.id
      size  = var.mgmt_node_disk_size
      type  = var.mgmt_node_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.pexip_infinity_network.name
    subnetwork = google_compute_subnetwork.pexip_subnets[var.default_region].name
    network_ip = google_compute_address.mgmt_internal_ip.address

    dynamic "access_config" {
      for_each = var.enable_public_ips ? [1] : []
      content {
        nat_ip = google_compute_address.mgmt_external_ip[0].address
      }
    }
  }

  metadata = {
    ssh-keys = "admin:${var.ssh_public_key}"
    management_node_config = jsonencode({
      hostname         = var.mgmt_node_hostname
      domain          = var.mgmt_node_domain
      ip              = google_compute_address.mgmt_internal_ip.address
      mask            = "255.255.255.255"
      gw              = var.mgmt_node_gateway
      dns             = join(",", var.dns_servers)
      ntp             = join(",", var.ntp_servers)
      user            = "admin"
      pass            = var.mgmt_node_admin_password_hash
      admin_password  = var.mgmt_node_os_password_hash
      error_reports   = var.enable_error_reporting
      enable_analytics = var.enable_analytics
    })
  }

  allow_stopping_for_update = true

  labels = merge(var.labels, {
    environment = var.environment
    managed-by  = "terraform"
    role        = "management"
  })

  depends_on = [
    null_resource.image_creation_check
  ]
}

# Outputs for management node details
output "management_node_internal_ip" {
  description = "Internal IP address of the Management Node"
  value       = google_compute_instance.pexip_mgmt.network_interface[0].network_ip
}

output "management_node_external_ip" {
  description = "External IP address of the Management Node (if enabled)"
  value       = var.enable_public_ips ? google_compute_address.mgmt_external_ip[0].address : "No external IP assigned"
}

output "management_node_url" {
  description = "Management Node access URL"
  value       = var.enable_public_ips ? "https://${google_compute_address.mgmt_external_ip[0].address}" : "https://${google_compute_instance.pexip_mgmt.network_interface[0].network_ip}"
}