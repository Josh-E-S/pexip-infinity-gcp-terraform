output "transcoding_nodes" {
  description = "Map of transcoding node instances"
  value       = google_compute_instance.transcoding_nodes
}

output "proxy_nodes" {
  description = "Map of proxy node instances"
  value       = google_compute_instance.proxy_nodes
}

output "transcoding_public_ips" {
  description = "Map of transcoding node public IP addresses"
  value       = google_compute_address.transcoding_public_ips
}

output "proxy_public_ips" {
  description = "Map of proxy node public IP addresses"
  value       = google_compute_address.proxy_public_ips
}
