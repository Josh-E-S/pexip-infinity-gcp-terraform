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
  }
}

# =============================================================================
# Local Variables
# =============================================================================

locals {
  # System configuration defaults
  system_configs = {
    dns_config = {
      servers = coalesce(var.dns_servers, ["8.8.8.8", "8.8.4.4"])
    }
    ntp_config = {
      servers = coalesce(var.ntp_servers, ["time.google.com"])
    }
  }

  # SSH key configuration
  ssh_public_key = var.ssh_key_path != null ? "${var.mgmt_node.admin_username}:${file(var.ssh_key_path)}" : null

  # Management node configuration defaults
  mgmt_node_config = {
    tags = concat(["pexip", "management"], try(var.mgmt_node.additional_tags, []))
    metadata = merge(
      {
        startup-script = file("${path.module}/scripts/mgmt_node_startup.sh")
      },
      local.ssh_public_key != null ? {
        ssh-keys = local.ssh_public_key
      } : {}
    )
  }
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
        can(regex("^\\$pbkdf2-sha256\\$", var.mgmt_node.admin_password_hash)) &&
        can(regex("^\\$6\\$rounds=", var.mgmt_node.os_password_hash))
      )
      error_message = "Management node password hashes must be in correct format (PBKDF2-SHA256 for admin, SHA-512 for OS)"
    }

    # Management Node Network Configuration
    precondition {
      condition = (
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.mgmt_node.hostname)) &&
        can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.mgmt_node.domain)) &&
        can(cidrhost(var.mgmt_node.subnet_cidr, 1))
      )
      error_message = "Invalid management node network configuration"
    }

    # Conference Node Configuration
    precondition {
      condition = alltrue([
        for _, node in var.transcoding_nodes : contains(keys(local.subnet_configs), node.region)
      ])
      error_message = "All transcoding nodes must be in regions with defined subnets"
    }

    precondition {
      condition = alltrue([
        for _, node in var.proxy_nodes : contains(keys(local.subnet_configs), node.region)
      ])
      error_message = "All proxy nodes must be in regions with defined subnets"
    }

    # Machine Type Validation
    precondition {
      condition = alltrue(concat(
        [var.mgmt_node.machine_type],
        [for node in var.transcoding_nodes : node.machine_type],
        [for node in var.proxy_nodes : node.machine_type]
      ))
      error_message = "Invalid machine type specified"
    }

    # DNS and NTP Configuration
    precondition {
      condition = length(local.system_configs.dns_config.servers) > 0
      error_message = "At least one DNS server must be configured"
    }

    precondition {
      condition = length(local.system_configs.ntp_config.servers) > 0
      error_message = "At least one NTP server must be configured"
    }
  }
}
