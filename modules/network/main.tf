terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# =============================================================================
# Network Data Sources
# =============================================================================
data "google_compute_network" "network" {
  name = var.network_name
}

data "google_compute_subnetwork" "subnets" {
  for_each = var.regions
  name     = each.value.subnet_name
  region   = each.key
}

# =============================================================================
# Management Node Inbound Rules
# =============================================================================

# Admin UI Access
resource "google_compute_firewall" "mgmt_admin" {
  name          = "${local.firewall_prefix}-mgmt-admin"
  network       = data.google_compute_network.network.name
  description   = local.ports.management.admin.description
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.admin.tcp
  }
}

# SSH Access
resource "google_compute_firewall" "mgmt_ssh" {
  count         = var.services.enable_ssh ? 1 : 0
  name          = "${local.firewall_prefix}-mgmt-ssh"
  network       = data.google_compute_network.network.name
  description   = local.ports.management.ssh.description
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.management, local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.ssh.tcp
  }
}

# Conferencing Node Provisioning Access
resource "google_compute_firewall" "mgmt_conf_provisioning" {
  count         = var.services.enable_conf_provisioning ? 1 : 0
  name          = "${local.firewall_prefix}-mgmt-conf-provisioning"
  network       = data.google_compute_network.network.name
  description   = local.ports.management.conf_provisioning.description
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.conf_provisioning.tcp
  }
}

# =============================================================================
# Call Services (Inbound Rules)
# =============================================================================

# SIP
resource "google_compute_firewall" "sip" {
  count         = var.services.enable_sip ? 1 : 0
  name          = "${local.firewall_prefix}-sip"
  network       = data.google_compute_network.network.name
  description   = local.ports.conferencing.sip.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  dynamic "allow" {
    for_each = local.ports.conferencing.sip
    content {
      protocol = allow.key
      ports    = allow.value
    }
  }
}

# H.323
resource "google_compute_firewall" "h323" {
  count         = var.services.enable_h323 ? 1 : 0
  name          = "${local.firewall_prefix}-h323"
  network       = data.google_compute_network.network.name
  description   = local.ports.conferencing.h323.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  dynamic "allow" {
    for_each = local.ports.conferencing.h323
    content {
      protocol = allow.key
      ports    = allow.value
    }
  }
}

# Teams
resource "google_compute_firewall" "teams" {
  count         = var.services.enable_teams ? 1 : 0
  name          = "${local.firewall_prefix}-teams"
  network       = data.google_compute_network.network.name
  description   = local.ports.conferencing.teams.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  dynamic "allow" {
    for_each = local.ports.conferencing.teams
    content {
      protocol = allow.key
      ports    = allow.value
    }
  }
}

# Google Meet
resource "google_compute_firewall" "gmeet" {
  count         = var.services.enable_gmeet ? 1 : 0
  name          = "${local.firewall_prefix}-gmeet"
  network       = data.google_compute_network.network.name
  description   = local.ports.conferencing.gmeet.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  dynamic "allow" {
    for_each = local.ports.conferencing.gmeet
    content {
      protocol = allow.key
      ports    = allow.value
    }
  }
}

# =============================================================================
# Internal Node Communication
# =============================================================================

# Internal node communication (IPsec)
resource "google_compute_firewall" "internal_node" {
  name        = "${local.firewall_prefix}-internal-node"
  network     = data.google_compute_network.network.name
  description = local.ports.internal.description
  direction   = "INGRESS"
  source_tags = [local.tags.management, local.tags.transcoding, local.tags.proxy]
  target_tags = [local.tags.management, local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "udp"
    ports    = local.ports.internal.udp
  }

  allow {
    protocol = local.ports.internal.protocols[0]  # ESP protocol
  }
}
