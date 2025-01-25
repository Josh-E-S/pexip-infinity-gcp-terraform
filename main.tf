# =============================================================================
# APIs
# =============================================================================
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_resource_manager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# =============================================================================
# APIs
# =============================================================================
module "apis" {
  source     = "./modules/apis"
  project_id = var.project_id
}

# =============================================================================
# Images
# =============================================================================
module "images" {
  source = "./modules/images"

  project_id = var.project_id
  region     = var.management_node.region
  images     = var.pexip_images
  apis       = module.apis
}

# =============================================================================
# Network
# =============================================================================
module "network" {
  source = "./modules/network"

  project_id        = var.project_id
  regions           = var.regions
  management_access = var.management_access
  services          = var.services
}

# =============================================================================
# SSH Key
# =============================================================================
module "ssh" {
  source     = "./modules/ssh"
  project_id = var.project_id
}

# =============================================================================
# Management Node
# =============================================================================
module "management_node" {
  source = "./modules/nodes"

  type           = "management"
  name           = var.management_node.name
  region         = var.management_node.region
  network_id     = [for r in module.network.networks : r.id if r.name == local.mgmt_network][0]
  subnet_id      = [for s in module.network.subnets : s.id if s.region == var.management_node.region][0]
  public_ip      = var.management_node.public_ip
  machine_type   = var.management_node.machine_type
  image_name     = module.images.images.management.name
  apis           = module.apis
  ssh_public_key = module.ssh.public_key
}

# Get management region's network
locals {
  mgmt_network = [for r in var.regions : r.network if r.region == var.management_node.region][0]
}

# =============================================================================
# Transcoding Nodes
# =============================================================================
module "transcoding_nodes" {
  for_each = var.transcoding_nodes.regional_config

  source = "./modules/nodes"

  type           = "transcoding"
  name           = each.value.name
  region         = each.key
  network_id     = module.network.networks[local.region_networks[each.key]].id
  subnet_id      = module.network.subnets[each.key].id
  public_ip      = each.value.public_ip
  image_name     = module.images.images.conferencing.name
  machine_type   = each.value.machine_type
  apis           = module.apis
  ssh_public_key = module.ssh.public_key
}

# =============================================================================
# Proxy Nodes
# =============================================================================
module "proxy_nodes" {
  for_each = var.proxy_nodes.regional_config

  source = "./modules/nodes"

  type           = "proxy"
  name           = each.value.name
  region         = each.key
  network_id     = module.network.networks[local.region_networks[each.key]].id
  subnet_id      = module.network.subnets[each.key].id
  public_ip      = each.value.public_ip
  image_name     = module.images.images.conferencing.name
  machine_type   = each.value.machine_type
  apis           = module.apis
  ssh_public_key = module.ssh.public_key
}

# Map of regions to their networks
locals {
  region_networks = { for r in var.regions : r.region => r.network }
}
