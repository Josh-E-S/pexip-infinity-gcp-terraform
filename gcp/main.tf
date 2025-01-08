# =============================================================================
# Provider Configuration
# =============================================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

# =============================================================================
# Validation Checks
# =============================================================================

resource "null_resource" "precondition_checks" {
  lifecycle {
    # Management Node Password Validation
    precondition {
      condition = (
        var.mgmt_node.admin_password_hash != "" &&
        var.mgmt_node.os_password_hash != "" &&
        can(regex("^pbkdf2-sha256\\$", var.mgmt_node.admin_password_hash)) &&
        can(regex("^sha512\\$", var.mgmt_node.os_password_hash))
      )
      error_message = "Management node password hashes must be in correct format (PBKDF2-SHA256 for admin, SHA-512 for OS)"
    }

    # Management Node Network Configuration
    precondition {
      condition = (
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.mgmt_node.hostname)) &&
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.mgmt_node.domain))
      )
      error_message = "Invalid management node hostname or domain configuration"
    }

    # Region and Zone Configuration
    precondition {
      condition = alltrue([
        for pool in var.transcoding_node_pools : contains(keys(var.regions), pool.region)
      ])
      error_message = "All transcoding node pools must be in regions with defined configurations"
    }

    precondition {
      condition = alltrue([
        for pool in var.proxy_node_pools : contains(keys(var.regions), pool.region)
      ])
      error_message = "All proxy node pools must be in regions with defined configurations"
    }

    # Management Node Region/Zone Check
    precondition {
      condition = (
        contains(keys(var.regions), var.mgmt_node.region) &&
        contains(var.regions[var.mgmt_node.region].zones, var.mgmt_node.zone)
      )
      error_message = "Management node must be in a configured region and zone"
    }

    # Image Configuration Check
    precondition {
      condition = (
        can(fileexists(var.pexip_images.management.source_file)) &&
        can(fileexists(var.pexip_images.conferencing.source_file))
      )
      error_message = "Pexip image files must exist at the specified paths"
    }

    # Service Configuration Checks
    precondition {
      condition = (
        var.transcoding_services.ports.media.udp_range.start < var.transcoding_services.ports.media.udp_range.end &&
        var.proxy_services.ports.media.udp_range.start < var.proxy_services.ports.media.udp_range.end
      )
      error_message = "Media port ranges must be valid (start < end)"
    }

    # System Configuration
    precondition {
      condition     = length(var.dns_servers) > 0 && length(var.ntp_servers) > 0
      error_message = "At least one DNS server and one NTP server must be configured"
    }
  }
}
