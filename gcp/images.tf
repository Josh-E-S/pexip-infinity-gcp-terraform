# =============================================================================
# Storage Bucket for Pexip Images
# =============================================================================
resource "google_storage_bucket" "pexip_images" {
  name                        = "${var.project_id}-pexip-images"
  location                    = var.regions[keys(var.regions)[0]] # Use first region
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = {
    managed-by = "terraform"
    component  = "images"
    product    = "pexip-infinity"
  }
}

# =============================================================================
# Management Node Image
# =============================================================================
locals {
  mgmt_image_name = coalesce(
    var.pexip_images.management.name,
    "pexip-infinity-mgmt-${var.pexip_version}"
  )
}

# Upload Management Node image to Cloud Storage
resource "google_storage_bucket_object" "mgmt_image" {
  name   = "pexip-infinity-mgmt-${var.pexip_version}.tar.gz"
  source = var.pexip_images.management.source_file
  bucket = google_storage_bucket.pexip_images.name

  depends_on = [google_storage_bucket.pexip_images]
}

# Create Management Node custom image
resource "google_compute_image" "mgmt_image" {
  name = local.mgmt_image_name

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.mgmt_image.name}"
  }

  labels = {
    managed-by = "terraform"
    component  = "management"
    product    = "pexip-infinity"
    version    = replace(var.pexip_version, ".", "-")
  }

  timeouts {
    create = "15m"
  }

  depends_on = [google_storage_bucket_object.mgmt_image]
}

# =============================================================================
# Conference Node Image
# =============================================================================
locals {
  conference_image_name = coalesce(
    var.pexip_images.conferencing.name,
    "pexip-infinity-conference-${var.pexip_version}"
  )
}

# Upload Conference Node image to Cloud Storage
resource "google_storage_bucket_object" "conference_image" {
  name   = "pexip-infinity-conference-${var.pexip_version}.tar.gz"
  source = var.pexip_images.conferencing.source_file
  bucket = google_storage_bucket.pexip_images.name

  depends_on = [google_storage_bucket.pexip_images]
}

# Create Conference Node custom image
resource "google_compute_image" "conference_image" {
  name = local.conference_image_name

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.conference_image.name}"
  }

  labels = {
    managed-by = "terraform"
    component  = "conference"
    product    = "pexip-infinity"
    version    = replace(var.pexip_version, ".", "-")
  }

  timeouts {
    create = "15m"
  }

  depends_on = [google_storage_bucket_object.conference_image]
}
