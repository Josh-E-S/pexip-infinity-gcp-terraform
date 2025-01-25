# =============================================================================
# Node Module Outputs
# =============================================================================

output "instances" {
  description = "Created instances"
  value = {
    for i in range(local.instance_count) : google_compute_instance.node[i].name => {
      name       = google_compute_instance.node[i].name
      private_ip = google_compute_address.internal_ip[i].address
      public_ip  = var.public_ip ? google_compute_address.external_ip[i].address : null
    }
  }
}

output "internal_ips" {
  description = "List of internal IP addresses"
  value       = google_compute_address.internal_ip[*].address
}

output "external_ips" {
  description = "List of external IP addresses (if public IP is enabled)"
  value       = var.public_ip ? google_compute_address.external_ip[*].address : []
}

output "instance_count" {
  description = "Number of instances created"
  value       = local.instance_count
}

output "node_type" {
  description = "Type of nodes created"
  value       = var.type
}

output "names" {
  description = "Names of the created instances"
  value       = google_compute_instance.node[*].name
}

output "public_ips" {
  description = "Public IPs of the created instances"
  value = [
    for i in range(local.instance_count) :
    var.public_ip ? google_compute_address.external_ip[i].address : null
  ]
}

output "private_ips" {
  description = "Private IPs of the created instances"
  value       = google_compute_address.internal_ip[*].address
}
