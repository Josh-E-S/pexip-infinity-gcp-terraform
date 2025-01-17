# =============================================================================
# Required Google Cloud APIs
# =============================================================================

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

  # Set to false to prevent issues with dependent services
  disable_on_destroy = false

  # Do not disable dependent services automatically
  disable_dependent_services = false
}

# Add dependencies to resources that require these APIs
locals {
  api_dependencies = [for api in google_project_service.apis : api.id]
}
