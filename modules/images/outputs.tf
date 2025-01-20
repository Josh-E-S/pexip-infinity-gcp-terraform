output "mgmt_image" {
  description = "The management node image"
  value       = google_compute_image.mgmt_image
}

output "mgmt_image_id" {
  description = "The ID of the management node image"
  value       = google_compute_image.mgmt_image.id
}

output "mgmt_image_self_link" {
  description = "The self_link of the management node image"
  value       = google_compute_image.mgmt_image.self_link
}

output "conf_image" {
  description = "The conference node image"
  value       = google_compute_image.conf_image
}

output "conf_image_id" {
  description = "The ID of the conference node image"
  value       = google_compute_image.conf_image.id
}

output "conf_image_self_link" {
  description = "The self_link of the conference node image"
  value       = google_compute_image.conf_image.self_link
}

output "storage_bucket" {
  description = "The storage bucket containing the Pexip images"
  value       = google_storage_bucket.pexip_images
}
