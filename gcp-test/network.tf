# =============================================================================
# VPC Network
# =============================================================================
# Create new network if not using existing
resource "google_compute_network" "pexip_network" {
  count                   = var.use_existing_network ? 0 : 1
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = var.network_routing_mode
}

# Data source for existing network
data "google_compute_network" "existing_network" {
  count = var.use_existing_network ? 1 : 0
  name  = var.existing_network_name
}

# Local for current network id and subnet references
locals {
  network_id   = var.use_existing_network ? data.google_compute_network.existing_network[0].id : google_compute_network.pexip_network[0].id
  network_name = var.use_existing_network ? data.google_compute_network.existing_network[0].name : google_compute_network.pexip_network[0].name

  # Subnet references for both new and existing subnets
  subnet_refs = {
    for region in distinct(concat(
      keys(local.subnet_configs),
      keys(var.existing_subnet_names)
    )) :
    region => {
      self_link     = var.use_existing_subnets ? data.google_compute_subnetwork.existing_subnets[region].self_link : google_compute_subnetwork.pexip_subnets[region].self_link
      ip_cidr_range = var.use_existing_subnets ? data.google_compute_subnetwork.existing_subnets[region].ip_cidr_range : google_compute_subnetwork.pexip_subnets[region].ip_cidr_range
    }
  }
}

# =============================================================================
# Subnets
# =============================================================================
# Create new subnets if not using existing
resource "google_compute_subnetwork" "pexip_subnets" {
  for_each = var.use_existing_subnets ? {} : local.subnet_configs

  name          = "${var.network_name}-subnet-${each.key}"
  ip_cidr_range = each.value.cidr
  network       = local.network_id
  region        = each.key
}

# Data source for existing subnets
data "google_compute_subnetwork" "existing_subnets" {
  for_each = var.use_existing_subnets ? var.existing_subnet_names : {}

  name   = each.value
  region = each.key
}

# =============================================================================
# Management Node Firewall Rules
# =============================================================================

# Administrative Access (Web UI and SSH)
resource "google_compute_firewall" "mgmt_admin" {
  name          = local.mgmt_node_firewall_rules.admin.name
  network       = local.network_name
  description   = local.mgmt_node_firewall_rules.admin.description
  direction     = local.mgmt_node_firewall_rules.admin.direction
  source_ranges = local.mgmt_node_firewall_rules.admin.source_ranges
  target_tags   = local.mgmt_node_firewall_rules.admin.target_tags

  dynamic "allow" {
    for_each = local.mgmt_node_firewall_rules.admin.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# Optional Services (LDAP, SMTP, Syslog)
resource "google_compute_firewall" "mgmt_services" {
  name          = local.mgmt_node_firewall_rules.services.name
  network       = local.network_name
  description   = local.mgmt_node_firewall_rules.services.description
  direction     = local.mgmt_node_firewall_rules.services.direction
  source_ranges = local.mgmt_node_firewall_rules.services.source_ranges
  target_tags   = local.mgmt_node_firewall_rules.services.target_tags

  dynamic "allow" {
    for_each = local.mgmt_node_firewall_rules.services.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# =============================================================================
# Conference Node Common Firewall Rules
# =============================================================================

# Media Traffic
resource "google_compute_firewall" "conference_media" {
  name          = local.conference_node_common_rules.media.name
  network       = local.network_name
  description   = local.conference_node_common_rules.media.description
  direction     = local.conference_node_common_rules.media.direction
  source_ranges = local.conference_node_common_rules.media.source_ranges
  target_tags   = local.conference_node_common_rules.media.target_tags

  dynamic "allow" {
    for_each = local.conference_node_common_rules.media.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# Internal Communication
resource "google_compute_firewall" "internal_communication" {
  name          = local.conference_node_common_rules.internal.name
  network       = local.network_name
  description   = local.conference_node_common_rules.internal.description
  direction     = local.conference_node_common_rules.internal.direction
  source_ranges = local.conference_node_common_rules.internal.source_ranges
  target_tags   = local.conference_node_common_rules.internal.target_tags

  dynamic "allow" {
    for_each = local.conference_node_common_rules.internal.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# =============================================================================
# Protocol-Specific Firewall Rules
# =============================================================================

# Create firewall rules for each protocol
resource "google_compute_firewall" "protocol_rules" {
  for_each = {
    for protocol, rule in local.protocol_firewall_rules :
    protocol => rule
  }

  name          = each.value.name
  network       = local.network_name
  description   = each.value.description
  direction     = "INGRESS"
  source_ranges = var.conference_node_defaults.core_service_cidrs.media
  target_tags   = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# =============================================================================
# Service-Specific Firewall Rules
# =============================================================================

# Create firewall rules for each service
resource "google_compute_firewall" "service_rules" {
  for_each = {
    for service, rule in local.service_firewall_rules :
    service => rule
  }

  name          = each.value.name
  network       = local.network_name
  description   = each.value.description
  direction     = "INGRESS"
  source_ranges = var.conference_node_defaults.core_service_cidrs.media
  target_tags   = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# =============================================================================
# System Service Firewall Rules
# =============================================================================

# DNS and NTP access
resource "google_compute_firewall" "system_services" {
  name        = "pexip-system-services"
  network     = local.network_name
  description = "System services (DNS and NTP)"
  direction   = "EGRESS"
  destination_ranges = distinct(concat(
    local.system_configs.dns_config.cidrs,
    local.system_configs.ntp_config.cidrs
  ))
  target_tags = ["pexip"]

  allow {
    protocol = "udp"
    ports    = ["53", "123"] # DNS and NTP ports
  }

  allow {
    protocol = "tcp"
    ports    = ["53"] # DNS over TCP
  }
}
