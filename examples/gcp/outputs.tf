# Output validation results
output "validation_results" {
  description = "Results of infrastructure validation checks"
  value = {
    api_status         = local.api_status
    sa_exists          = local.sa_exists
    cidr_ranges_valid  = local.validate_cidr_overlap
    zones_valid        = local.validate_zones
    supported_machines = local.supported_machine_types
  }
}

# Network Outputs
output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.pexip_infinity_network.id
}

output "subnet_ids" {
  description = "Map of subnet IDs by region"
  value = {
    for region, subnet in google_compute_subnetwork.pexip_subnets : region => subnet.id
  }
}

output "firewall_rules" {
  description = "List of created firewall rule names"
  value = {
    internal     = google_compute_firewall.allow_internal.name
    management   = google_compute_firewall.allow_management.name
    provisioning = google_compute_firewall.allow_provisioning.name
    conferencing = google_compute_firewall.allow_conferencing.name
  }
}

# Management Node Outputs
output "management_node_details" {
  description = "Details of the Management Node"
  value = {
    name        = google_compute_instance.pexip_mgmt.name
    instance_id = google_compute_instance.pexip_mgmt.instance_id
    zone        = google_compute_instance.pexip_mgmt.zone
    internal_ip = google_compute_instance.pexip_mgmt.network_interface[0].network_ip
    external_ip = var.enable_public_ips ? google_compute_instance.pexip_mgmt.network_interface[0].access_config[0].nat_ip : "No external IP assigned"
    url         = var.enable_public_ips ? "https://${google_compute_instance.pexip_mgmt.network_interface[0].access_config[0].nat_ip}" : "https://${google_compute_instance.pexip_mgmt.network_interface[0].network_ip}"
  }
}

# Conference Node Outputs
output "conference_nodes" {
  description = "Details of deployed Conference Nodes"
  value = {
    for node in google_compute_instance.pexip_conf_nodes :
    node.name => {
      instance_id = node.instance_id
      zone        = node.zone
      internal_ip = node.network_interface[0].network_ip
      external_ip = var.enable_public_ips ? node.network_interface[0].access_config[0].nat_ip : "No external IP assigned"
      region      = split("-", node.zone)[0]
    }
  }
}

# Storage Outputs
output "storage_bucket" {
  description = "Details of the storage bucket"
  value = {
    name     = google_storage_bucket.pexip_images.name
    location = google_storage_bucket.pexip_images.location
    url      = google_storage_bucket.pexip_images.url
  }
}

# SSH Key Outputs
output "ssh_key_secret" {
  description = "Name of the Secret Manager secret containing the SSH private key"
  value       = google_secret_manager_secret.ssh_private_key.name
  sensitive   = true
}

# Image Outputs
output "images" {
  description = "Details of created custom images"
  value = {
    management_node = {
      name = google_compute_image.pexip_mgmt_image.name
      id   = google_compute_image.pexip_mgmt_image.id
    }
    conference_node = {
      name = google_compute_image.pexip_conf_image.name
      id   = google_compute_image.pexip_conf_image.id
    }
  }
}

# Resource Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    regions_deployed       = keys(var.conf_node_count)
    total_conference_nodes = sum(values(var.conf_node_count))
    public_access          = var.enable_public_ips ? "Enabled" : "Disabled"
    environment            = var.environment
  }
}
