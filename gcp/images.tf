# Create GCS bucket for Pexip images
resource "google_storage_bucket" "pexip_images" {
  name          = "${var.pexip_images_bucket}-${var.pexip_version}"
  location      = var.storage_bucket_location
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7 # Keep images for 7 days
    }
    action {
      type = "Delete"
    }
  }
}

# Upload Management Node image
resource "google_storage_bucket_object" "mgr_image" {
  name   = basename(var.pexip_mgr_image_source)
  source = var.pexip_mgr_image_source
  bucket = google_storage_bucket.pexip_images.name
}

# Upload Conference Node image
resource "google_storage_bucket_object" "conf_image" {
  name   = basename(var.pexip_conf_image_source)
  source = var.pexip_conf_image_source
  bucket = google_storage_bucket.pexip_images.name
}

# Create Management Node custom image
resource "google_compute_image" "mgr_node" {
  name = "pexip-mgr-${var.pexip_version}"

  raw_disk {
    source = "gs://${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.mgr_image.name}"
  }

  depends_on = [google_storage_bucket_object.mgr_image]
}

# Create Conference Node custom image
resource "google_compute_image" "conf_node" {
  name = "pexip-conf-${var.pexip_version}"

  raw_disk {
    source = "gs://${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.conf_image.name}"
  }

  depends_on = [google_storage_bucket_object.conf_image]
}