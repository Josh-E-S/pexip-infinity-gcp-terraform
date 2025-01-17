# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "ssh_private_key" {
  depends_on = [google_project_service.apis]
  secret_id = "${var.project_id}-pexip-ssh-key"

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

# Local for SSH key access
locals {
  ssh_public_key = "${var.mgmt_node.admin_username}:${tls_private_key.ssh.public_key_openssh}"
}
