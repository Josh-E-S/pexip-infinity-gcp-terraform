# Generate SSH key pair if none provided
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "ssh_private_key" {
  count     = var.ssh_public_key == "" ? 1 : 0
  secret_id = "${var.project_id}-pexip-ssh-private-key"
  
  replication {
    auto {}
  }

  labels = {
    terraform = "true"
    module    = "pexip"
  }
}

# Store the private key value
resource "google_secret_manager_secret_version" "ssh_private_key" {
  count       = var.ssh_public_key == "" ? 1 : 0
  secret      = google_secret_manager_secret.ssh_private_key[0].id
  secret_data = tls_private_key.ssh[0].private_key_pem
}

# Local for consistent SSH key access
locals {
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : "${tls_private_key.ssh[0].public_key_openssh} admin"
}
