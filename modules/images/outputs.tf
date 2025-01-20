output "mgmt_image" {
  description = "The management node image"
  value       = var.pexip_images.upload_files ? google_compute_image.mgmt_image[0] : data.google_compute_image.mgmt_image[0]
}

output "mgmt_image_id" {
  description = "The ID of the management node image"
  value       = var.pexip_images.upload_files ? google_compute_image.mgmt_image[0].id : data.google_compute_image.mgmt_image[0].id
}

output "mgmt_image_self_link" {
  description = "The self_link of the management node image"
  value       = var.pexip_images.upload_files ? google_compute_image.mgmt_image[0].self_link : data.google_compute_image.mgmt_image[0].self_link
}

output "conf_image" {
  description = "The conference node image"
  value       = var.pexip_images.upload_files ? google_compute_image.conf_image[0] : data.google_compute_image.conf_image[0]
}

output "conf_image_id" {
  description = "The ID of the conference node image"
  value       = var.pexip_images.upload_files ? google_compute_image.conf_image[0].id : data.google_compute_image.conf_image[0].id
}

output "conf_image_self_link" {
  description = "The self_link of the conference node image"
  value       = var.pexip_images.upload_files ? google_compute_image.conf_image[0].self_link : data.google_compute_image.conf_image[0].self_link
}

output "storage_bucket" {
  description = "The storage bucket containing the Pexip images"
  value       = google_storage_bucket.pexip_images
}
