# =============================================================================
# Network Outputs
# =============================================================================
output "network" {
  description = "Network configuration"
  value = {
    name    = module.network.network.name
    id      = module.network.network.id
    subnets = module.network.subnets
  }
}

output "firewall_rules" {
  description = "Created firewall rules"
  value       = module.network.firewall_rules
}

# =============================================================================
# Image Outputs
# =============================================================================
output "images" {
  description = "Created or referenced Pexip images"
  value       = module.images.images
}

output "bucket" {
  description = "GCS bucket details (if created)"
  value       = module.images.bucket
}

# =============================================================================
# Node Outputs
# =============================================================================
output "management_node" {
  description = "Management node details"
  value       = module.management_node.instances
}

output "transcoding_nodes" {
  description = "Transcoding nodes details"
  value = {
    for region, node in module.transcoding_nodes : region => node.instances
  }
}

output "proxy_nodes" {
  description = "Proxy nodes details"
  value = {
    for region, node in module.proxy_nodes : region => node.instances
  }
}

# =============================================================================
# Connection Information
# =============================================================================
output "z_connection_info" {
  description = "Connection information for Pexip nodes"
  value       = <<-EOT
    Management Node:
    %{for name, instance in module.management_node.instances~}
    - Admin Interface: https://${instance.public_ip}:8443
    - SSH Access: ssh admin@${instance.public_ip}
    %{endfor~}

    Transcoding Nodes:
    %{for region, node in module.transcoding_nodes~}
    ${region}:
    %{for name, instance in node.instances~}
    - ${instance.name}: ${instance.public_ip}
    %{endfor~}
    %{endfor~}

    Proxy Nodes:
    %{for region, node in module.proxy_nodes~}
    ${region}:
    %{for name, instance in node.instances~}
    - ${instance.name}: ${instance.public_ip}
    %{endfor~}
    %{endfor~}
  EOT
}

# =============================================================================
# Summary Outputs
# =============================================================================
output "summary" {
  description = "Summary of deployed resources"
  value = {
    network = {
      name    = module.network.network.name
      subnets = module.network.subnets
    }
    nodes = {
      management = {
        for name, instance in module.management_node.instances : name => {
          public_ip = instance.public_ip
        }
      }
      transcoding = {
        for region, node in module.transcoding_nodes : region => {
          count = length(node.instances)
          nodes = {
            for name, instance in node.instances : name => {
              public_ip = instance.public_ip
            }
          }
        }
      }
      proxy = {
        for region, node in module.proxy_nodes : region => {
          count = length(node.instances)
          nodes = {
            for name, instance in node.instances : name => {
              public_ip = instance.public_ip
            }
          }
        }
      }
    }
    images = module.images.images
  }
}
