# =============================================================================
# Network Outputs
# =============================================================================
output "networks" {
  description = "Network configurations"
  value       = module.network.networks
}

output "subnets" {
  description = "Subnet configurations"
  value       = module.network.subnets
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
    networks = {
      for name, network in module.network.networks : name => {
        subnets = {
          for region, subnet in module.network.subnets : region => subnet.name
          if subnet.network == network.name
        }
      }
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
          instances = {
            for name, instance in node.instances : name => {
              public_ip = instance.public_ip
            }
          }
        }
      }
      proxy = {
        for region, node in module.proxy_nodes : region => {
          count = length(node.instances)
          instances = {
            for name, instance in node.instances : name => {
              public_ip = instance.public_ip
            }
          }
        }
      }
    }
  }
}
