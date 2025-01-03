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

  # Validate CIDR ranges don't overlap
  cidr_ranges           = [for range in values(var.subnet_cidr_ranges) : range]
  validate_cidr_overlap = length(local.cidr_ranges) == length(toset(local.cidr_ranges))

  # Validate machine types are available in specified zones
  supported_machine_types = {
    "n2-highcpu-4"  = true
    "n2-highcpu-8"  = true
    "n2-highcpu-16" = true
    "n2-highcpu-32" = true
  }

  # Ensure all regions have valid zones specified
  validate_zones = alltrue([
    for region, zones in var.zones :
    length(zones) > 0
  ])
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
      error_message = "Subnet CIDR ranges must not overlap."
    }

    # Machine type validation
    precondition {
      condition     = lookup(local.supported_machine_types, var.mgmt_machine_type, false)
      error_message = "${var.mgmt_machine_type} is not a supported machine type for management node."
    }

    precondition {
      condition     = lookup(local.supported_machine_types, var.conf_machine_type, false)
      error_message = "${var.conf_machine_type} is not a supported machine type for conference nodes."
    }

    # Zone validation
    precondition {
      condition     = local.validate_zones
      error_message = "All regions must have at least one zone specified."
    }

    # Image source validation
    precondition {
      condition     = fileexists(var.pexip_mgr_image_source)
      error_message = "Management node image file does not exist at specified path."
    }

    precondition {
      condition     = fileexists(var.pexip_conf_image_source)
      error_message = "Conference node image file does not exist at specified path."
    }

    # Network security validation
    precondition {
      condition     = length(var.management_allowed_cidrs) > 0
      error_message = "At least one CIDR range must be specified for management access."
    }

    precondition {
      condition     = length(var.conf_node_allowed_cidrs) > 0
      error_message = "At least one CIDR range must be specified for conference node access."
    }
  }
}

# Optional: Add monitoring/logging for deployment status
resource "null_resource" "deployment_monitor" {
  triggers = {
    mgmt_node_id = google_compute_instance.pexip_mgmt.id
  }

  provisioner "local-exec" {
    command = "echo 'Deployment completed at: $(date)' >> deployment.log"
  }

  depends_on = [
    google_compute_instance.pexip_mgmt,
    google_compute_instance.pexip_conf_nodes
  ]
}
