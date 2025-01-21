# =============================================================================
# Infrastructure Information
# =============================================================================
output "infrastructure_info" {
  description = "Information about the infrastructure deployment"
  value = {
    project_id = var.project_id
    regions    = var.regions
    machine_types = {
      management  = module.management.instance.machine_type
      transcoding = [for instance in module.conference.transcoding_nodes : instance.machine_type]
      proxy       = [for instance in module.conference.proxy_nodes : instance.machine_type]
    }
  }
}

# =============================================================================
# Management Node
# =============================================================================
output "management_node" {
  description = "Information about the management node"
  value = {
    name         = module.management.instance.name
    internal_ip  = module.management.instance.network_interface[0].network_ip
    external_ip  = try(module.management.instance.network_interface[0].access_config[0].nat_ip, null)
    machine_type = module.management.instance.machine_type
    zone         = module.management.instance.zone
  }
}

# =============================================================================
# Conferencing Nodes
# =============================================================================
output "transcoding_nodes" {
  description = "Information about transcoding nodes"
  value = {
    for name, instance in module.conference.transcoding_nodes : name => {
      name         = instance.name
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
      machine_type = instance.machine_type
      zone         = instance.zone
      region       = regex("^([a-z]+-[a-z]+[0-9]+)", instance.zone)[0]
    }
  }
}

output "proxy_nodes" {
  description = "Information about proxy nodes (if any)"
  value = {
    for name, instance in module.conference.proxy_nodes : name => {
      name         = instance.name
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
      machine_type = instance.machine_type
      zone         = instance.zone
      region       = regex("^([a-z]+-[a-z]+[0-9]+)", instance.zone)[0]
    }
  }
}

# =============================================================================
# Network Details
# =============================================================================
output "network_details" {
  description = "Information about the network configuration"
  value = {
    network = {
      name = module.network.network.name
      id   = module.network.network.id
    }
  }
}

# =============================================================================
# Deployment Summary
# =============================================================================
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    project_id = var.project_id
    nodes = {
      management = {
        count  = 1
        region = var.mgmt_node.region
      }
      transcoding = {
        count   = length(module.conference.transcoding_nodes)
        regions = distinct([for name, node in module.conference.transcoding_nodes : regex("^([a-z]+-[a-z]+[0-9]+)", node.zone)[0]])
      }
      proxy = {
        count   = length(module.conference.proxy_nodes)
        regions = distinct([for name, node in module.conference.proxy_nodes : regex("^([a-z]+-[a-z]+[0-9]+)", node.zone)[0]])
      }
    }
  }
}

# =============================================================================
# Storage Information
# =============================================================================
output "storage_bucket" {
  description = "Information about the storage bucket"
  value = {
    name     = module.images.storage_bucket.name
    location = module.images.storage_bucket.location
    url      = module.images.storage_bucket.url
  }
}

# =============================================================================
# Image Information
# =============================================================================
output "images" {
  description = "Information about the Pexip images"
  value = {
    storage_bucket = module.images.storage_bucket.name
    management = {
      name      = module.images.mgmt_image.name
      self_link = module.images.mgmt_image.self_link
    }
    conference = {
      name      = module.images.conf_image.name
      self_link = module.images.conf_image.self_link
    }
  }
}

# =============================================================================
# Connection Information
# =============================================================================
output "z_connection_info" {
  description = "Connection information for the Pexip deployment"
  value       = <<-EOT
    ================================================================================
    Download and Setup SSH Key:
    --------------------------------------------------------------------------------
    # Download the private key from Secret Manager
    gcloud secrets versions access latest --secret="${var.project_id}-pexip-ssh-key" > pexip_key

    # Set correct permissions on the key file
    chmod 600 pexip_key

    ================================================================================
    Management Node SSH Connection:
    --------------------------------------------------------------------------------
    ssh -i pexip_key admin@${try(module.management.instance.network_interface[0].access_config[0].nat_ip, "")}

    ================================================================================
    Management Node Web Interface:
    --------------------------------------------------------------------------------
    https://${try(module.management.instance.network_interface[0].access_config[0].nat_ip, "")} #Inital Installer must be run before the web interface can be accessed

    ================================================================================
    Transcoding Node IPs:
    --------------------------------------------------------------------------------
    %{for node_key, node in module.conference.transcoding_nodes~}
    ${node.name}: https://${try(node.network_interface[0].access_config[0].nat_ip, "No public IP")}:8443 #Inital setup
    %{endfor~}

    %{if length(module.conference.proxy_nodes) > 0~}
    ================================================================================
    Proxy Node IPs:
    --------------------------------------------------------------------------------
    %{for node_key, node in module.conference.proxy_nodes~}
    ${node.name}: https://${try(node.network_interface[0].access_config[0].nat_ip, "No public IP")}:8443 #Inital setup
    %{endfor~}
    %{endif~}
    EOT
}
