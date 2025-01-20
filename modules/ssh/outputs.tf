output "public_key" {
  description = "The generated SSH public key"
  value       = local.ssh_public_key
}

output "private_key_secret" {
  description = "The Secret Manager secret containing the private key"
  value       = google_secret_manager_secret.ssh_private_key
}
