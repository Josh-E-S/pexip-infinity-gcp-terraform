terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

locals {
  required_apis = [
    "compute.googleapis.com",              # Compute Engine API
    "secretmanager.googleapis.com",        # Secret Manager API
    "storage.googleapis.com",              # Cloud Storage API
    "iam.googleapis.com",                  # Identity and Access Management API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "servicenetworking.googleapis.com"     # Service Networking API
  ]
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project = var.project_id
  service = each.value

  # Prevent issues with dependent services after destroy
  disable_on_destroy = false

  # Do not disable dependent services automatically to avoid other issues
  disable_dependent_services = false
}
