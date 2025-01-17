# =============================================================================
# Storage Bucket for Pexip Images
# =============================================================================
resource "google_storage_bucket" "pexip_images" {
  name                        = "${var.project_id}-pexip-images"
  location                    = keys(var.regions)[0] # Use first region
  force_destroy               = true
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.apis]

  labels = {
    managed-by = "terraform"
    component  = "images"
    product    = "pexip-infinity"
  }
}

# =============================================================================
# Management Node Image
# =============================================================================

# Upload Management Node image to Cloud Storage if needed
resource "google_storage_bucket_object" "mgmt_image" {
  name   = "pexip-infinity-mgmt-${var.pexip_version}.tar.gz"
  source = var.pexip_images.upload_files ? var.pexip_images.management.source_file : null
  bucket = google_storage_bucket.pexip_images.name

    timeouts {
    create = "60m"
  }

}

# Create or reference Management Node image
resource "google_compute_image" "mgmt_image" {
  name = var.pexip_images.management.image_name

  dynamic "raw_disk" {
    for_each = var.pexip_images.upload_files ? [1] : []
    content {
      source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.mgmt_image.name}"
    }
  }

  source_image = var.pexip_images.upload_files ? null : var.pexip_images.management.image_name

  labels = {
    managed-by = "terraform"
    component  = "management"
    product    = "pexip-infinity"
    version    = replace(var.pexip_version, ".", "-")
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# =============================================================================
# Conference Node Image
# =============================================================================

# Upload Conference Node image to Cloud Storage if needed
resource "google_storage_bucket_object" "conference_image" {
  name   = "pexip-infinity-conf-${var.pexip_version}.tar.gz"
  source = var.pexip_images.upload_files ? var.pexip_images.conference.source_file : null
  bucket = google_storage_bucket.pexip_images.name

    timeouts {
    create = "60m"
  }
}

# Create or reference Conference Node image
resource "google_compute_image" "conf_image" {
  name = var.pexip_images.conference.image_name

  dynamic "raw_disk" {
    for_each = var.pexip_images.upload_files ? [1] : []
    content {
      source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.conference_image.name}"
    }
  }

  source_image = var.pexip_images.upload_files ? null : var.pexip_images.conference.image_name

  labels = {
    managed-by = "terraform"
    component  = "conference"
    product    = "pexip-infinity"
    version    = replace(var.pexip_version, ".", "-")
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }
}
