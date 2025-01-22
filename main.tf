# =============================================================================
# APIs
# =============================================================================
module "apis" {
  source = "./modules/apis"
  project_id = var.project_id
}

# =============================================================================
# Images
# =============================================================================
module "images" {
  source = "./modules/images"

  project_id     = var.project_id
  region         = var.region
  pexip_version = var.pexip_version
  images        = var.pexip_images
  apis          = module.apis
}

# =============================================================================
# Network
# =============================================================================
module "network" {
  source = "./modules/network"

  project_id       = var.project_id
  use_existing     = var.network_config.use_existing_network
  network_name     = var.network_config.network_name
  regions         = var.deployment_regions
  management_access = var.management_access
  services         = var.pexip_services
  apis             = module.apis
}

# =============================================================================
# Management Node
# =============================================================================
module "management_node" {
  source = "./modules/nodes"

  project_id  = var.project_id
  type        = "management"
  name        = var.management_node.name
  region      = var.management_node.region
  network_id  = module.network.network.id
  subnet_id   = module.network.subnets[var.management_node.region].id
  public_ip   = var.management_node.public_ip
  image_name  = module.images.images.management.name
  apis        = module.apis
}

# =============================================================================
# Transcoding Nodes
# =============================================================================
module "transcoding_nodes" {
  source   = "./modules/nodes"
  for_each = var.transcoding_nodes.regional_config

  project_id  = var.project_id
  type        = "transcoding"
  name        = each.value.name
  region      = each.key
  network_id  = module.network.network.id
  subnet_id   = module.network.subnets[each.key].id
  public_ip   = each.value.public_ip
  image_name  = module.images.images.conferencing.name
  apis        = module.apis
  quantity    = each.value.count
  machine_type = each.value.machine_type
}

# =============================================================================
# Proxy Nodes
# =============================================================================
module "proxy_nodes" {
  source   = "./modules/nodes"
  for_each = var.proxy_nodes.regional_config

  project_id  = var.project_id
  type        = "proxy"
  name        = each.value.name
  region      = each.key
  network_id  = module.network.network.id
  subnet_id   = module.network.subnets[each.key].id
  public_ip   = each.value.public_ip
  image_name  = module.images.images.conferencing.name
  apis        = module.apis
  quantity    = each.value.count
  machine_type = each.value.machine_type
}
