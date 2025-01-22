# Generate SSH key pair if not provided
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "ssh_private_key" {
  count      = var.ssh_public_key == "" ? 1 : 0
  depends_on = [var.apis]
  secret_id  = "${var.project_id}-pexip-${var.type}-ssh-key"

  replication {
    auto {}
  }

  labels = {
    terraform = "true"
    module    = "pexip"
    type      = var.type
  }
}

# Store the private key value
resource "google_secret_manager_secret_version" "ssh_private_key" {
  count       = var.ssh_public_key == "" ? 1 : 0
  secret      = google_secret_manager_secret.ssh_private_key[0].id
  secret_data = tls_private_key.ssh[0].private_key_pem
}

locals {
  # Use provided key or generated one
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : "admin:${tls_private_key.ssh[0].public_key_openssh}"
}
