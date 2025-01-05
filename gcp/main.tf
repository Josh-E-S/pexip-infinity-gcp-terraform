# Check if required APIs are enabled
data "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "storage-api.googleapis.com",
    "iam.googleapis.com"
  ])
  project = var.project_id
  service = each.value
}

# Verify service account permissions
data "google_service_account" "terraform_sa" {
  account_id = split("@", data.google_client_config.current.service_account)[0]
  project    = var.project_id
}

data "google_client_config" "current" {}

# Local variables for validation
locals {
  # Required roles for the service account
  required_roles = [
    "roles/compute.admin",
    "roles/secretmanager.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser"
  ]

  # Get primary region (priority = 1)
  primary_region = [
    for region, config in var.regions :
    region if config.priority == 1
  ][0]

  # Validate CIDR ranges don't overlap
  all_cidrs = [for region in var.regions : region.cidr]
  validate_cidr_overlap = length(local.all_cidrs) == length(toset(local.all_cidrs))

  # Validate machine types meet Pexip requirements
  supported_machine_types = {
    for type in ["n2-highcpu-4", "n2-highcpu-8", "n2-highcpu-16", "n2-highcpu-32"] :
    type => contains(["n2", "n2d", "c2"], split("-", type)[0])
  }
}

provider "google" {
  project = var.project_id
  region  = local.primary_region
}

# Comprehensive precondition checks
resource "null_resource" "precondition_checks" {
  lifecycle {
    # Required variables checks
    precondition {
      condition     = var.mgmt_node_admin_password_hash != null && var.mgmt_node_admin_password_hash != ""
      error_message = "Management node admin password hash must be provided."
    }

    precondition {
      condition     = var.mgmt_node_os_password_hash != null && var.mgmt_node_os_password_hash != ""
      error_message = "Management node OS password hash must be provided."
    }

    # Network validation
    precondition {
      condition     = local.validate_cidr_overlap
      error_message = "CIDR ranges must not overlap between regions."
    }

    # Primary region validation
    precondition {
      condition     = length(local.primary_region) > 0
      error_message = "Exactly one region must be designated as primary (priority = 1)."
    }

    # Machine type validation
    precondition {
      condition     = alltrue([for machine_type, is_valid in local.supported_machine_types : is_valid])
      error_message = "One or more machine types do not meet Pexip's requirements. Use N2, N2D, or C2 series."
    }
  }
}
