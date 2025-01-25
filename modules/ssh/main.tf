# =============================================================================
# SSH Module
# =============================================================================

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

# =============================================================================
# Node SSH Key Generation
# =============================================================================

# One SSH key pair to rule them all!
resource "google_secret_manager_secret" "ssh_key" {
  secret_id = "${var.project_id}-pexip-ssh-key"
  replication {
    auto {}
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_secret_manager_secret_version" "ssh_key" {
  secret      = google_secret_manager_secret.ssh_key.id
  secret_data = tls_private_key.ssh.private_key_pem
}

output "public_key" {
  description = "The public key to use for SSH access"
  value       = tls_private_key.ssh.public_key_openssh
}
