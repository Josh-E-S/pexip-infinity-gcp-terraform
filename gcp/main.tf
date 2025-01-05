# Local variables for validation
locals {
  # Get primary region (priority = 1)
  primary_region = [
    for region, config in var.regions :
    region if config.priority == 1
  ][0]

  # Validate CIDR ranges don't overlap
  all_cidrs             = [for region in var.regions : region.cidr]
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

    # Management node bootstrap values validation
    precondition {
      condition = (
        var.mgmt_node_admin_password_hash != "" &&
        var.mgmt_node_os_password_hash != "" &&
        can(regex("^\\$pbkdf2-sha256\\$", var.mgmt_node_admin_password_hash)) &&
        can(regex("^\\$6\\$rounds=", var.mgmt_node_os_password_hash))
      )
      error_message = "Management node password hashes must be provided and in correct format. Admin password should be PBKDF2-SHA256 and OS password should be SHA-512. Use the password generation tool in tools/generate_passwords.py"
    }

    precondition {
      condition = (
        var.mgmt_node_hostname != "" &&
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.mgmt_node_hostname)) &&
        length(var.mgmt_node_hostname) <= 64
      )
      error_message = "Hostname must be a valid DNS label (alphanumeric, hyphens allowed in middle, max 64 chars)"
    }

    precondition {
      condition = (
        var.mgmt_node_domain != "" &&
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.mgmt_node_domain)) &&
        length(var.mgmt_node_domain) <= 253
      )
      error_message = "Domain must be a valid DNS domain name"
    }

    precondition {
      condition = (
        var.mgmt_node_gateway != "" &&
        can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.mgmt_node_gateway)) &&
        alltrue([for octet in split(".", var.mgmt_node_gateway) : tonumber(octet) >= 0 && tonumber(octet) <= 255])
      )
      error_message = "Gateway must be a valid IPv4 address"
    }

    precondition {
      condition = length(var.dns_servers) > 0 && alltrue([
        for dns in var.dns_servers :
        can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", dns)) &&
        alltrue([for octet in split(".", dns) : tonumber(octet) >= 0 && tonumber(octet) <= 255])
      ])
      error_message = "At least one valid DNS server IPv4 address must be provided"
    }

    precondition {
      condition = length(var.ntp_servers) > 0 && alltrue([
        for ntp in var.ntp_servers :
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", ntp)) ||
        (
          can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", ntp)) &&
          alltrue([for octet in split(".", ntp) : tonumber(octet) >= 0 && tonumber(octet) <= 255])
        )
      ])
      error_message = "At least one valid NTP server (hostname or IPv4) must be provided"
    }

    precondition {
      condition     = var.ssh_public_key != "" ? can(regex("^ssh-[^ ]+ [^ ]+ admin$", var.ssh_public_key)) : true
      error_message = "If provided, SSH public key must be in OpenSSH format and include 'admin' username"
    }

    precondition {
      condition     = alltrue([for machine_type, is_valid in local.supported_machine_types : is_valid])
      error_message = "One or more machine types do not meet Pexip's requirements. Use N2, N2D, or C2 series."
    }
  }
}
