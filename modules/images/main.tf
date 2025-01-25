# =============================================================================
# Images Module
# =============================================================================

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
locals {
  bucket_name = "${var.project_id}-pexip-images"
}

# Create storage bucket
resource "google_storage_bucket" "pexip_images" {
  count                       = var.images.upload_files ? 1 : 0
  name                        = local.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  depends_on                  = [var.apis]
}

# Upload management node image
resource "google_storage_bucket_object" "management_image" {
  count  = var.images.upload_files ? 1 : 0
  name   = basename(var.images.management.source_file)
  source = var.images.management.source_file
  bucket = google_storage_bucket.pexip_images[0].name
}

# Upload conferencing node image (used by both transcoding and proxy nodes)
resource "google_storage_bucket_object" "conferencing_image" {
  count  = var.images.upload_files ? 1 : 0
  name   = basename(var.images.conferencing.source_file)
  source = var.images.conferencing.source_file
  bucket = google_storage_bucket.pexip_images[0].name
}

# Create management node image
resource "google_compute_image" "management" {
  count = var.images.upload_files ? 1 : 0
  name  = var.images.management.image_name

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images[0].name}/${google_storage_bucket_object.management_image[0].name}"
  }

  labels = {
    managed-by = "terraform"
    node-type  = "management"
    product    = "pexip-infinity"
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }

  depends_on = [google_storage_bucket_object.management_image]
}

# Create conferencing node image (used by both transcoding and proxy nodes)
resource "google_compute_image" "conferencing" {
  count = var.images.upload_files ? 1 : 0
  name  = var.images.conferencing.image_name

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images[0].name}/${google_storage_bucket_object.conferencing_image[0].name}"
  }

  labels = {
    managed-by = "terraform"
    node-type  = "conferencing"
    product    = "pexip-infinity"
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }

  depends_on = [google_storage_bucket_object.conferencing_image]
}
