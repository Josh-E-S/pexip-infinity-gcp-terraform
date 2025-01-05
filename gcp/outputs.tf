# Output validation results
output "validation_results" {
  description = "Results of infrastructure validation checks"
  value = {
    cidr_ranges_valid   = local.validate_cidr_overlap
    primary_region      = local.primary_region
    machine_types_valid = local.supported_machine_types
  }
}

# Management Node Outputs
output "management_node" {
  description = "Management node details"
  value = {
    name         = google_compute_instance.management_node.name
    internal_ip  = google_compute_instance.management_node.network_interface[0].network_ip
    external_ip  = try(google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip, null)
    machine_type = google_compute_instance.management_node.machine_type
    zone         = google_compute_instance.management_node.zone
    region       = local.primary_region
  }
}

# Conference Node Outputs
output "transcoding_nodes" {
  description = "Transcoding conference node details by region"
  value = {
    for region, instances in {
      for k, v in google_compute_instance.transcoding_nodes : v.zone => v...
      } : region => [
      for instance in instances : {
        name         = instance.name
        internal_ip  = instance.network_interface[0].network_ip
        external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
        machine_type = instance.machine_type
        zone         = instance.zone
      }
    ]
  }
}

output "proxy_nodes" {
  description = "Proxy conference node details by region"
  value = {
    for region, instances in {
      for k, v in google_compute_instance.proxy_nodes : v.zone => v...
      } : region => [
      for instance in instances : {
        name         = instance.name
        internal_ip  = instance.network_interface[0].network_ip
        external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
        machine_type = instance.machine_type
        zone         = instance.zone
      }
    ]
  }
}

# Network Outputs
output "network_details" {
  description = "Network configuration details"
  value = {
    network_name = google_compute_network.pexip_infinity_network.name
    subnets = {
      for key, subnet in google_compute_subnetwork.pexip_subnets : key => {
        name          = subnet.name
        ip_cidr_range = subnet.ip_cidr_range
        region        = subnet.region
      }
    }
  }
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the Pexip Infinity deployment"
  value = {
    project_id = var.project_id
    regions    = keys(var.regions)
    node_counts = {
      management = 1
      transcoding = {
        for region, config in var.regions : region => config.conference_nodes.transcoding.count
      }
      proxy = {
        for region, config in var.regions : region => try(config.conference_nodes.proxy.count, 0)
      }
    }
    public_access = var.network_config.enable_public_ips
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for Pexip Infinity"
  value = {
    management_interface = var.network_config.enable_public_ips ? format(
      "https://%s",
      google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip
      ) : format(
      "https://%s",
      google_compute_instance.management_node.network_interface[0].network_ip
    )
    ssh_command = var.network_config.enable_public_ips ? format(
      "ssh admin@%s",
      google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip
      ) : format(
      "ssh admin@%s",
      google_compute_instance.management_node.network_interface[0].network_ip
    )
  }
  sensitive = false
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
