# =============================================================================
# Validation Results
# =============================================================================

output "validation_results" {
  description = "Results of infrastructure validation checks"
  value = {
    network = {
      subnet_generation = var.auto_generate_subnets ? "auto" : "manual"
      subnet_regions    = keys(local.subnet_configs)
      cidrs             = [for subnet in local.subnet_configs : subnet.cidr]
    }
    nodes = {
      management = {
        region = var.mgmt_node.region
        zone   = var.mgmt_node.zone
      }
      transcoding = {
        count   = length(var.transcoding_nodes)
        regions = distinct([for node in var.transcoding_nodes : node.region])
      }
      proxy = {
        count   = length(var.proxy_nodes)
        regions = distinct([for node in var.proxy_nodes : node.region])
      }
    }
    machine_types = {
      management  = var.mgmt_node.machine_type
      transcoding = distinct([for node in var.transcoding_nodes : node.machine_type])
      proxy       = distinct([for node in var.proxy_nodes : node.machine_type])
    }
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
    region       = var.mgmt_node.region
    hostname     = var.mgmt_node.hostname
    domain       = var.mgmt_node.domain
  }
}

# Conference Node Outputs
output "transcoding_nodes" {
  description = "Transcoding conference node details"
  value = {
    for name, instance in google_compute_instance.transcoding_nodes : name => {
      name         = instance.name
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
      machine_type = instance.machine_type
      zone         = instance.zone
      region       = var.transcoding_nodes[name].region
      protocols    = var.transcoding_nodes[name].enable_protocols
      services     = var.transcoding_nodes[name].enable_services
    }
  }
}

output "proxy_nodes" {
  description = "Proxy conference node details"
  value = {
    for name, instance in google_compute_instance.proxy_nodes : name => {
      name         = instance.name
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
      machine_type = instance.machine_type
      zone         = instance.zone
      region       = var.proxy_nodes[name].region
      protocols    = var.proxy_nodes[name].enable_protocols
      services     = var.proxy_nodes[name].enable_services
    }
  }
}

# Network Outputs
output "network_details" {
  description = "Network configuration details"
  value = {
    network_name = google_compute_network.pexip_network.name
    subnets = {
      for key, subnet in google_compute_subnetwork.pexip_subnets : key => {
        name          = subnet.name
        ip_cidr_range = subnet.ip_cidr_range
        region        = subnet.region
      }
    }
    firewall_rules = {
      management = {
        admin    = google_compute_firewall.mgmt_admin.name
        services = google_compute_firewall.mgmt_services.name
      }
      conference = {
        media     = google_compute_firewall.conference_media.name
        internal  = google_compute_firewall.internal_communication.name
        protocols = [for rule in google_compute_firewall.protocol_rules : rule.name]
        services  = [for rule in google_compute_firewall.service_rules : rule.name]
      }
    }
  }
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the Pexip Infinity deployment"
  value = {
    project_id    = var.project_id
    environment   = var.environment
    pexip_version = var.pexip_version

    nodes = {
      management = {
        count         = 1
        public_access = var.mgmt_node.public_ip
      }
      transcoding = {
        count   = length(var.transcoding_nodes)
        regions = distinct([for node in var.transcoding_nodes : node.region])
      }
      proxy = {
        count   = length(var.proxy_nodes)
        regions = distinct([for node in var.proxy_nodes : node.region])
      }
    }
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for Pexip Infinity"
  value = {
    admin_interface = format(
      "https://%s",
      coalesce(
        try(google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip, null),
        google_compute_instance.management_node.network_interface[0].network_ip
      )
    )
    ssh_command = format(
      "ssh admin@%s",
      coalesce(
        try(google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip, null),
        google_compute_instance.management_node.network_interface[0].network_ip
      )
    )
  }

  sensitive = true
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
  description = "Pexip Infinity image details"
  value = {
    storage_bucket = google_storage_bucket.pexip_images.name
    management = {
      name    = google_compute_image.mgmt_image.name
      version = var.pexip_version
    }
    conference = {
      name    = google_compute_image.conference_image.name
      version = var.pexip_version
    }
  }
}