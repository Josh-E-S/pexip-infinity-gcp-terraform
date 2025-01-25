# =============================================================================
# APIs Module - Enable Required GCP APIs
# =============================================================================

locals {
  required_apis = [
    "cloudresourcemanager.googleapis.com",  # Required for IAM
    "compute.googleapis.com",               # Required for GCE
    "iam.googleapis.com",                   # Required for IAM
    "secretmanager.googleapis.com",         # Required for SSH key storage
    "storage.googleapis.com"                # Required for GCS
  ]
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  service            = each.value
  project           = var.project_id
  disable_on_destroy = false

  # Prevent issues with dependent services after destroy
  disable_dependent_services = false
}
