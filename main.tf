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

    # Zone Validation
    precondition {
      condition = alltrue([
        for pool in var.transcoding_node_pools : contains(var.regions[pool.region].zones, pool.zone)
      ])
      error_message = "All transcoding node pools must use zones defined in their region configuration"
    }

    precondition {
      condition = alltrue([
        for pool in var.proxy_node_pools : contains(var.regions[pool.region].zones, pool.zone)
      ])
      error_message = "All proxy node pools must use zones defined in their region configuration"
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
        !var.pexip_images.upload_files || (
          can(fileexists(var.pexip_images.management.source_file)) &&
          can(fileexists(var.pexip_images.conference.source_file))
        )
      )
      error_message = "When upload_files is true, Pexip image files must exist at the specified paths"
    }

    # Service Configuration Checks
    precondition {
      condition = (
        var.transcoding_services.ports.media.udp_range.start < var.transcoding_services.ports.media.udp_range.end &&
        var.proxy_services.ports.media.udp_range.start < var.proxy_services.ports.media.udp_range.end
      )
      error_message = "Media port ranges must be valid (start < end)"
    }

    # Pool Configuration Checks
    precondition {
      condition = alltrue([
        for pool in var.transcoding_node_pools : (
          pool.count > 0 &&
          (pool.disk_size == null || pool.disk_size >= 50)
        )
      ])
      error_message = "Transcoding node pools must have count > 0 and disk_size >= 50 if specified"
    }
  }
}

# =============================================================================
# APIs Module
# =============================================================================
module "apis" {
  source = "./modules/apis"

  project_id = var.project_id
}

# =============================================================================
# SSH Module
# =============================================================================
module "ssh" {
  source = "./modules/ssh"

  project_id = var.project_id
  apis       = module.apis
}

# =============================================================================
# Network Module
# =============================================================================
module "network" {
  source = "./modules/network"

  network_name          = var.network_name
  mgmt_node_name        = var.mgmt_node_name
  transcoding_node_name = var.transcoding_node_name
  proxy_node_name       = var.proxy_node_name

  # Management node configuration
  mgmt_node     = var.mgmt_node
  mgmt_services = var.mgmt_services

  # Conference node configuration
  transcoding_services = var.transcoding_services
  proxy_services       = var.proxy_services

  # Provisioning configuration
  conferencing_nodes_provisioning = var.conferencing_nodes_provisioning

  # APIs dependency
  apis = module.apis
}

# =============================================================================
# Images Module
# =============================================================================
module "images" {
  source = "./modules/images"

  project_id    = var.project_id
  regions       = var.regions
  pexip_version = var.pexip_version
  pexip_images  = var.pexip_images

  # APIs dependency
  apis = module.apis
}

# =============================================================================
# Management Node Module
# =============================================================================
module "management" {
  source = "./modules/management"

  mgmt_node_name = var.mgmt_node_name
  mgmt_node      = local.mgmt_node
  regions        = var.regions
  network        = module.network.network
  mgmt_image     = module.images.mgmt_image
  ssh_public_key = module.ssh.public_key

  # APIs dependency
  apis = module.apis
}

# =============================================================================
# Conference Nodes Module
# =============================================================================
module "conference" {
  source = "./modules/conference"

  transcoding_node_name = var.transcoding_node_name
  proxy_node_name       = var.proxy_node_name
  regions               = var.regions

  # Node pools configuration
  transcoding_node_pools = var.transcoding_node_pools
  proxy_node_pools       = var.proxy_node_pools

  # Service configurations
  transcoding_services = var.transcoding_services
  proxy_services       = var.proxy_services

  # Network configuration from network module
  network = module.network.network

  # Image configuration from images module
  conf_image = module.images.conf_image

  # Management node reference
  management_node = {
    id = module.management.instance_id
  }

  # SSH key configuration from ssh module
  ssh_public_key = module.ssh.public_key

  # APIs dependency
  apis = module.apis
}
