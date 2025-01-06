# =============================================================================
# Storage Bucket for Pexip Images
# =============================================================================

resource "google_storage_bucket" "pexip_images" {
  name                        = "${var.project_id}-pexip-images-${var.environment}"
  location                    = var.storage_bucket_location
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    component   = "images"
    product     = "pexip-infinity"
  }
}

# =============================================================================
# Management Node Image
# =============================================================================

# Upload Management Node image to Cloud Storage
resource "google_storage_bucket_object" "mgmt_image" {
  name   = "pexip-infinity-mgmt-${var.pexip_version}.tar.gz"
  source = var.mgmt_node_image_path
  bucket = google_storage_bucket.pexip_images.name

  depends_on = [google_storage_bucket.pexip_images]
}

# Create Management Node custom image
resource "google_compute_image" "mgmt_image" {
  name = "pexip-infinity-mgmt-${var.pexip_version}"

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.mgmt_image.name}"
  }

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    component   = "management"
    product     = "pexip-infinity"
    version     = replace(var.pexip_version, ".", "-")
  }

  timeouts {
    create = "15m"
  }

  depends_on = [google_storage_bucket_object.mgmt_image]
}

# =============================================================================
# Conference Node Images
# =============================================================================

# Upload Conference Node image to Cloud Storage
resource "google_storage_bucket_object" "conference_image" {
  name   = "pexip-infinity-conference-${var.pexip_version}.tar.gz"
  source = var.conference_node_image_path
  bucket = google_storage_bucket.pexip_images.name

  depends_on = [google_storage_bucket.pexip_images]
}

# Create Conference Node custom image
resource "google_compute_image" "conference_image" {
  name = "pexip-infinity-conference-${var.pexip_version}"

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.conference_image.name}"
  }

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    component   = "conference"
    product     = "pexip-infinity"
    version     = replace(var.pexip_version, ".", "-")
  }

  timeouts {
    create = "15m"
  }

  depends_on = [google_storage_bucket_object.conference_image]
}

# Null resource to check image creation completion
resource "null_resource" "image_creation_check" {
  depends_on = [
    google_compute_image.mgmt_image,
    google_compute_image.conference_image
  ]

  provisioner "local-exec" {
    command = "echo 'Pexip images creation completed. Management Node and Conference Node images are ready for use.'"
  }
}
