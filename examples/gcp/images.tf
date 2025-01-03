# Storage bucket for Pexip disk images
resource "google_storage_bucket" "pexip_images" {
  name                        = "${var.project_id}-${var.pexip_images_bucket}"
  location                    = var.storage_bucket_location
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = merge(var.labels, {
    environment = var.environment
    managed-by  = "terraform"
  })
}

# Upload Management Node image to Cloud Storage
resource "google_storage_bucket_object" "mgmt_node_image" {
  name   = "pexip-mgr-v${var.pexip_version}.tar.gz"
  source = var.pexip_mgr_image_source
  bucket = google_storage_bucket.pexip_images.name

  depends_on = [google_storage_bucket.pexip_images]
}

# Upload Conference Node image to Cloud Storage
resource "google_storage_bucket_object" "conf_node_image" {
  name   = "pexip-conf-v${var.pexip_version}.tar.gz"
  source = var.pexip_conf_image_source
  bucket = google_storage_bucket.pexip_images.name

  depends_on = [google_storage_bucket.pexip_images]
}

# Create Management Node custom image
resource "google_compute_image" "pexip_mgmt_image" {
  name = "pexip-mgr-v${var.pexip_version}"

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.mgmt_node_image.name}"
  }

  labels = merge(var.labels, {
    environment = var.environment
    managed-by  = "terraform"
    version     = replace(var.pexip_version, ".", "-")
  })

  timeouts {
    create = "15m"
  }
}

# Create Conference Node custom image
resource "google_compute_image" "pexip_conf_image" {
  name = "pexip-conf-v${var.pexip_version}"

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.pexip_images.name}/${google_storage_bucket_object.conf_node_image.name}"
  }

  labels = merge(var.labels, {
    environment = var.environment
    managed-by  = "terraform"
    version     = replace(var.pexip_version, ".", "-")
  })

  timeouts {
    create = "15m"
  }
}

# Null resource to check image creation completion
resource "null_resource" "image_creation_check" {
  depends_on = [
    google_compute_image.pexip_mgmt_image,
    google_compute_image.pexip_conf_image
  ]

  provisioner "local-exec" {
    command = "echo 'Pexip images creation completed. Management Node and Conference Node images are ready for use.'"
  }
}
