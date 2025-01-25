# =============================================================================
# Images Module Outputs
# =============================================================================

output "images" {
  description = "Created or referenced Pexip images"
  value = {
    management = {
      name = var.images.upload_files ? google_compute_image.management[0].name : var.images.management.image_name
      # Only output id and self_link if we created the image
      id        = var.images.upload_files ? google_compute_image.management[0].id : null
      self_link = var.images.upload_files ? google_compute_image.management[0].self_link : null
    }
    conferencing = {
      name = var.images.upload_files ? google_compute_image.conferencing[0].name : var.images.conferencing.image_name
      # Only output id and self_link if we created the image
      id        = var.images.upload_files ? google_compute_image.conferencing[0].id : null
      self_link = var.images.upload_files ? google_compute_image.conferencing[0].self_link : null
    }
  }
}

output "bucket" {
  description = "GCS bucket details (if created)"
  value = var.images.upload_files ? {
    name      = google_storage_bucket.pexip_images[0].name
    self_link = google_storage_bucket.pexip_images[0].self_link
  } : null
}
