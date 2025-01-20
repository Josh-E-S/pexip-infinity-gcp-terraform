terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# =============================================================================
# Storage Bucket for Pexip Images
# =============================================================================
resource "google_storage_bucket" "pexip_images" {
  name                        = "${var.project_id}-pexip-images"
  location                    = keys(var.regions)[0] # Use first region
  force_destroy               = true
  uniform_bucket_level_access = true
  depends_on                  = [var.apis]

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
  count  = var.pexip_images.upload_files ? 1 : 0
  name   = "pexip-infinity-mgmt-${var.pexip_version}.tar.gz"
  source = var.pexip_images.management.source_file
  bucket = google_storage_bucket.pexip_images.name

  timeouts {
    create = "60m"
  }
}

# Data source for existing Management Node image
data "google_compute_image" "mgmt_image" {
  count   = var.pexip_images.upload_files ? 0 : 1
  name    = var.pexip_images.management.image_name
  project = var.project_id
}

# Create Management Node image when uploading files
resource "google_compute_image" "mgmt_image" {
  count = var.pexip_images.upload_files ? 1 : 0
  name  = var.pexip_images.management.image_name

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.mgmt_image[0].name}"
  }

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
  count  = var.pexip_images.upload_files ? 1 : 0
  name   = "pexip-infinity-conf-${var.pexip_version}.tar.gz"
  source = var.pexip_images.conference.source_file
  bucket = google_storage_bucket.pexip_images.name

  timeouts {
    create = "60m"
  }
}

# Data source for existing Conference Node image
data "google_compute_image" "conf_image" {
  count   = var.pexip_images.upload_files ? 0 : 1
  name    = var.pexip_images.conference.image_name
  project = var.project_id
}

# Create Conference Node image when uploading files
resource "google_compute_image" "conf_image" {
  count = var.pexip_images.upload_files ? 1 : 0
  name  = var.pexip_images.conference.image_name

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.conference_image[0].name}"
  }

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
