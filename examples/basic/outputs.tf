# =============================================================================
# Essential Outputs
# =============================================================================

output "management_node" {
  description = "Management node details"
  value       = module.pexip.management_node
}

output "transcoding_nodes" {
  description = "Transcoding nodes details"
  value       = module.pexip.transcoding_nodes
}

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
    %{for name, instance in module.pexip.management_node~}
    Web Interface: https://${instance.public_ip != null ? instance.public_ip : instance.private_ip}
    SSH Access: ssh -i pexip_key admin@${instance.public_ip != null ? instance.public_ip : instance.private_ip}
    %{endfor~}

    ================================================================================
    Transcoding Node IPs:
    ================================================================================
    %{for region, instances in module.pexip.transcoding_nodes~}
    ${region}:
    %{for name, instance in instances~}
    ${name}: https://${instance.public_ip != null ? instance.public_ip : instance.private_ip}:8443 #Initial bootstrap
    %{endfor~}
    %{endfor~}

    ================================================================================
    Note: Initial configuration of the Management Node is required before accessing
    the web interface. Please refer to Pexip documentation for setup instructions.
    EOT
}
