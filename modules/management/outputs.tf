output "instance" {
  description = "The management node instance"
  value       = google_compute_instance.management_node
}

output "instance_id" {
  description = "The ID of the management node instance"
  value       = google_compute_instance.management_node.id
}

output "instance_self_link" {
  description = "The self_link of the management node instance"
  value       = google_compute_instance.management_node.self_link
}

output "internal_ip" {
  description = "The internal IP address of the management node"
  value       = google_compute_address.mgmt_internal_ip.address
}

output "external_ip" {
  description = "The external IP address of the management node (if enabled)"
  value       = try(google_compute_address.mgmt_external_ip[0].address, null)
}
