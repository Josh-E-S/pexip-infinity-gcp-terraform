# =============================================================================
# Network Module Outputs
# =============================================================================

output "networks" {
  description = "Map of network names to their network objects"
  value       = data.google_compute_network.networks
}

output "subnets" {
  description = "Map of regions to their subnet objects"
  value       = data.google_compute_subnetwork.subnets
}
