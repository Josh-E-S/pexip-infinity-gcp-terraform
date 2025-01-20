output "network" {
  description = "The VPC network"
  value       = data.google_compute_network.network
}

output "network_name" {
  description = "The name of the VPC network"
  value       = data.google_compute_network.network.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = data.google_compute_network.network.id
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = data.google_compute_network.network.self_link
}
