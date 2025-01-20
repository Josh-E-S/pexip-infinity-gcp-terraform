terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "ssh_private_key" {
  depends_on = [var.apis]
  secret_id  = "${var.project_id}-pexip-ssh-key"

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
  secret      = google_secret_manager_secret.ssh_private_key.id
  secret_data = tls_private_key.ssh.private_key_pem
}

# Local for SSH key access. Sets the admin user to "admin" for GCP
locals {
  ssh_public_key = "admin:${tls_private_key.ssh.public_key_openssh}"
}
