# =============================================================================
# Network Outputs
# =============================================================================

output "networks" {
  description = "Map of network names to network details"
  value       = module.pexip.networks
}

output "subnets" {
  description = "Map of subnet names to subnet details"
  value       = module.pexip.subnets
}

# =============================================================================
# Storage Outputs
# =============================================================================

output "bucket" {
  description = "Details of the GCS bucket created for Pexip images"
  value       = module.pexip.bucket
}

output "images" {
  description = "Details of the Pexip images created"
  value       = module.pexip.images
}

# =============================================================================
# Node Instance Outputs
# =============================================================================

output "management_node" {
  description = "Details of the management node instances"
  value       = module.pexip.management_node
}

output "transcoding_nodes" {
  description = "Details of the transcoding node instances"
  value       = module.pexip.transcoding_nodes
}

output "proxy_nodes" {
  description = "Details of the proxy node instances"
  value       = module.pexip.proxy_nodes
}

# =============================================================================
# Summary Output
# =============================================================================

output "summary" {
  description = "Summary of the Pexip deployment"
  value       = module.pexip.summary
}

# =============================================================================
# Connection Information
# =============================================================================

output "z_connection_info" { # Using z_ to ensure this is the last output
  description = "Connection information for the Pexip deployment"
  value       = <<-EOT
    ================================================================================
    Download and Setup SSH Key:
    ================================================================================
    # Download the private key from Secret Manager
    gcloud secrets versions access latest --secret="${var.project_id}-pexip-ssh-key" > pexip_key

    # Set correct permissions on the key file
    chmod 600 pexip_key

    ================================================================================
    Management Node:
    ================================================================================
    Web Interface: https://${values(module.pexip.management_node)[0].public_ip}
    SSH Access: ssh -i pexip_key admin@${values(module.pexip.management_node)[0].public_ip}

    ================================================================================
    Transcoding Node IPs:
    ================================================================================
    %{for region, instances in module.pexip.transcoding_nodes~}
    ${region}:
    %{for name, instance in instances~}
    ${name}: https://${instance.public_ip}:8443 #Initial bootstrap
    %{endfor~}
    %{endfor~}

    ================================================================================
    Proxy Node IPs:
    ================================================================================
    %{for region, instances in module.pexip.proxy_nodes~}
    ${region}:
    %{for name, instance in instances~}
    ${name}: https://${instance.public_ip}:8443 #Initial bootstrap when enabled
    %{endfor~}
    %{endfor~}

    ================================================================================
    Note: Initial configuration of the Management Node is required before accessing
    the web interface. Please refer to Pexip documentation for setup instructions.
    EOT
}
