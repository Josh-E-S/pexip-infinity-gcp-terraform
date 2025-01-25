# =============================================================================
# Network Outputs
# =============================================================================
output "networks" {
  description = "Details of all VPC networks used for Pexip deployment, including network names, IDs, and routing configurations"
  value       = module.network.networks
}

output "subnets" {
  description = "Details of all subnets created or referenced in each region, including CIDR ranges and network assignments"
  value       = module.network.subnets
}

# =============================================================================
# Image Outputs
# =============================================================================
output "images" {
  description = "Details of Pexip Infinity images (management and conferencing) either created from local files or referenced from existing images"
  value       = module.images.images
}

output "bucket" {
  description = "Google Cloud Storage bucket details used for image upload, including name and URL. Only populated if images were uploaded from local files"
  value       = module.images.bucket
}

# =============================================================================
# Node Outputs
# =============================================================================
output "management_node" {
  description = "Detailed information about the management node, including instance name, IP addresses (public and private), and machine type"
  value       = module.management_node.instances
}

output "transcoding_nodes" {
  description = "Map of transcoding nodes by region, including instance details like names, IP addresses, and machine types for each conferencing node"
  value = {
    for region, node in module.transcoding_nodes : region => node.instances
  }
}

output "proxy_nodes" {
  description = "Map of proxy nodes by region, including instance details like names, IP addresses, and machine types for each proxy node"
  value = {
    for region, node in module.proxy_nodes : region => node.instances
  }
}

# =============================================================================
# Connection Information
# =============================================================================
output "z_connection_info" { # Using z_ to ensure this is the last output
  description = "Formatted connection details for all Pexip nodes, including admin UI URLs and SSH access information for the management node, and IP addresses for transcoding and proxy nodes"
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
