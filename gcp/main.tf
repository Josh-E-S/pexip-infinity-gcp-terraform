# =============================================================================
# Validation Checks
# =============================================================================

# Default values for management node
locals {
  default_mgmt_node = {
    machine_type = "n2-standard-4"
    disk_size    = 50
    disk_type    = "pd-standard"
  }
}

# Merge default values with user-provided values
locals {
  mgmt_node = merge(local.default_mgmt_node, var.mgmt_node)
}

resource "null_resource" "precondition_checks" {
  lifecycle {

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
        can(fileexists(var.pexip_images.conference.source_file))
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
  }
}
