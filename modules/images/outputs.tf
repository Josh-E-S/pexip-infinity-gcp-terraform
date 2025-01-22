# =============================================================================
# Images Module Outputs
# =============================================================================

output "images" {
  description = "Created or referenced Pexip images"
  value = {
    management = {
      id        = var.images.upload_files ? google_compute_image.management[0].id : var.images.management.image_name
      name      = var.images.upload_files ? google_compute_image.management[0].name : var.images.management.image_name
      self_link = var.images.upload_files ? google_compute_image.management[0].self_link : var.images.management.image_name
    }
    conferencing = {
      id        = var.images.upload_files ? google_compute_image.conferencing[0].id : var.images.conferencing.image_name
      name      = var.images.upload_files ? google_compute_image.conferencing[0].name : var.images.conferencing.image_name
      self_link = var.images.upload_files ? google_compute_image.conferencing[0].self_link : var.images.conferencing.image_name
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
