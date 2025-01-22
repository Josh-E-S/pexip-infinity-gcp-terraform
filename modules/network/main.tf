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
# VPC Network
# =============================================================================
data "google_compute_network" "existing" {
  count = var.use_existing ? 1 : 0
  name  = var.network_name
}

locals {
  network = var.use_existing ? data.google_compute_network.existing[0] : null
}

# =============================================================================
# Subnets
# =============================================================================
data "google_compute_subnetwork" "existing" {
  for_each = var.use_existing ? var.regions : {}
  name     = each.value.subnet_name
  region   = each.key
}

locals {
  subnets = var.use_existing ? data.google_compute_subnetwork.existing : {}
}

# =============================================================================
# Management Node Firewall Rules
# =============================================================================
# Admin UI Access
resource "google_compute_firewall" "mgmt_admin" {
  name          = "pexip-mgmt-admin"
  network       = local.network.name
  description   = "Management node administrative access"
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
  count         = var.management_access.enable_ssh ? 1 : 0
  name          = "${local.firewall_prefix}-mgmt-ssh"
  network       = local.network.name
  description   = "Management node SSH access"
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = [local.mgmt_ports.ssh]
  }
}

# Node Provisioning
resource "google_compute_firewall" "mgmt_provisioning" {
  count         = var.management_access.enable_provisioning ? 1 : 0
  name          = "${local.firewall_prefix}-mgmt-provisioning"
  network       = local.network.name
  description   = "Management node provisioning interface"
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = [local.mgmt_ports.provisioning]
  }
}

# Teams Event Hub (Outbound)
resource "google_compute_firewall" "mgmt_teams_hub" {
  count              = var.services.enable_teams ? 1 : 0
  name               = "${local.firewall_prefix}-mgmt-teams-hub"
  network            = local.network.name
  description        = "Management node Teams Event Hub (outbound to Azure)"
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]  # Azure Event Hub endpoint
  target_tags        = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = [local.mgmt_ports.teams_hub]
  }
}

# DNS
resource "google_compute_firewall" "mgmt_dns" {
  name          = "pexip-mgmt-dns"
  network       = local.network.name
  description   = "Management node DNS"
  direction     = "INGRESS"
  source_ranges = var.service_ranges.dns
  target_tags   = [local.tags.management]

  dynamic "allow" {
    for_each = local.ports.management.dns
    content {
      protocol = allow.key  # tcp or udp
      ports    = allow.value
    }
  }
}

# NTP
resource "google_compute_firewall" "mgmt_ntp" {
  name          = "pexip-mgmt-ntp"
  network       = local.network.name
  description   = "Management node NTP"
  direction     = "INGRESS"
  source_ranges = var.service_ranges.ntp
  target_tags   = [local.tags.management]

  allow {
    protocol = "udp"
    ports    = local.ports.management.ntp.udp
  }
}

# Syslog
resource "google_compute_firewall" "mgmt_syslog" {
  name          = "pexip-mgmt-syslog"
  network       = local.network.name
  description   = "Management node Syslog"
  direction     = "INGRESS"
  source_ranges = var.service_ranges.syslog
  target_tags   = [local.tags.management]

  allow {
    protocol = "udp"
    ports    = local.ports.management.syslog.udp
  }
}

# SMTP
resource "google_compute_firewall" "mgmt_smtp" {
  name          = "pexip-mgmt-smtp"
  network       = local.network.name
  description   = "Management node SMTP"
  direction     = "INGRESS"
  source_ranges = var.service_ranges.smtp
  target_tags   = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.smtp.tcp
  }
}

# LDAP
resource "google_compute_firewall" "mgmt_ldap" {
  name          = "pexip-mgmt-ldap"
  network       = local.network.name
  description   = "Management node LDAP"
  direction     = "INGRESS"
  source_ranges = var.service_ranges.ldap
  target_tags   = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.ldap.tcp
  }
}

# =============================================================================
# Conferencing Node Firewall Rules
# =============================================================================

# Media Traffic (shared by all conferencing nodes)
resource "google_compute_firewall" "media" {
  name          = "pexip-media"
  network       = local.network.name
  description   = "Media traffic for conferencing nodes"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "udp"
    ports    = ["${local.ports.media.start}-${local.ports.media.end}"]
  }
}

# SIP Signaling
resource "google_compute_firewall" "sip" {
  count         = var.services.enable_sip ? 1 : 0
  name          = "${local.firewall_prefix}-sip"
  network       = local.network.name
  description   = "SIP signaling for conferencing nodes"
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  dynamic "allow" {
    for_each = local.ports.conferencing.sip
    content {
      protocol = allow.key  # tcp or udp
      ports    = allow.value
    }
  }
}

# H.323 Signaling
resource "google_compute_firewall" "h323" {
  count         = var.services.enable_h323 ? 1 : 0
  name          = "${local.firewall_prefix}-h323"
  network       = local.network.name
  description   = "H.323 signaling for conferencing nodes"
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  dynamic "allow" {
    for_each = local.ports.conferencing.h323
    content {
      protocol = allow.key  # tcp or udp
      ports    = allow.value
    }
  }
}

# Teams Integration
resource "google_compute_firewall" "teams" {
  count         = var.services.enable_teams ? 1 : 0
  name          = "${local.firewall_prefix}-teams"
  network       = local.network.name
  description   = "Teams integration for conferencing nodes"
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.transcoding]

  dynamic "allow" {
    for_each = local.ports.conferencing.teams
    content {
      protocol = allow.key  # tcp or udp
      ports    = allow.value
    }
  }
}

# Google Meet Integration
resource "google_compute_firewall" "gmeet" {
  count         = var.services.enable_gmeet ? 1 : 0
  name          = "${local.firewall_prefix}-gmeet"
  network       = local.network.name
  description   = "Google Meet integration for conferencing nodes"
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.transcoding]

  dynamic "allow" {
    for_each = local.ports.conferencing.gmeet
    content {
      protocol = allow.key  # tcp or udp
      ports    = allow.value
    }
  }
}

# Internal Node Communication
resource "google_compute_firewall" "internal_udp" {
  name          = "${local.firewall_prefix}-internal-udp"
  network       = local.network.name
  description   = "Internal UDP communication between nodes"
  direction     = "INGRESS"
  source_tags   = [local.tags.management, local.tags.transcoding, local.tags.proxy]
  target_tags   = [local.tags.management, local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "udp"
    ports    = local.ports.internal.udp
  }
}

resource "google_compute_firewall" "internal_esp" {
  name          = "${local.firewall_prefix}-internal-esp"
  network       = local.network.name
  description   = "Internal IPsec ESP communication between nodes"
  direction     = "INGRESS"
  source_tags   = [local.tags.management, local.tags.transcoding, local.tags.proxy]
  target_tags   = [local.tags.management, local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "esp"
  }
}
