# =============================================================================
# Network Data Sources
# =============================================================================
locals {
  networks = distinct([for r in var.regions : r.network])
}

data "google_compute_network" "networks" {
  for_each = toset([for r in var.regions : r.network])
  project  = var.project_id
  name     = each.value
}

data "google_compute_subnetwork" "subnets" {
  for_each  = { for idx, r in var.regions : r.region => r }
  project   = var.project_id
  name      = each.value.subnet_name
  region    = each.key
}

# =============================================================================
# Management Node Inbound Rules
# =============================================================================

# Admin UI Access - create for each network
resource "google_compute_firewall" "mgmt_admin" {
  for_each      = toset(local.networks)
  name          = "${local.firewall_prefix}-mgmt-admin-${substr(md5(each.value), 0, 4)}"
  network       = each.value
  description   = local.ports.management.admin.description
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.management]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.admin.tcp
  }
}

# SSH Access - create for each network
resource "google_compute_firewall" "mgmt_ssh" {
  for_each      = var.services.enable_ssh ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-mgmt-ssh-${substr(md5(each.value), 0, 4)}"
  network       = each.value
  description   = local.ports.management.ssh.description
  direction     = "INGRESS"
  source_ranges = var.management_access.cidr_ranges
  target_tags   = [local.tags.management, local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "tcp"
    ports    = local.ports.management.ssh.tcp
  }
}

# Conferencing Node Provisioning Access - create for each network
resource "google_compute_firewall" "mgmt_conf_provisioning" {
  for_each      = var.services.enable_conf_provisioning ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-mgmt-conf-provisioning-${substr(md5(each.value), 0, 4)}"
  network       = each.value
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

# SIP - create for each network
resource "google_compute_firewall" "sip" {
  for_each      = var.services.enable_sip ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-sip-${substr(md5(each.value), 0, 4)}"
  network       = each.value
  description   = local.ports.conferencing.sip.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "tcp"
    ports    = local.ports.conferencing.sip.tcp
  }

  allow {
    protocol = "udp"
    ports    = local.ports.conferencing.sip.udp
  }
}

# H.323 - create for each network
resource "google_compute_firewall" "h323" {
  for_each      = var.services.enable_h323 ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-h323-${substr(md5(each.value), 0, 4)}"
  network       = each.value
  description   = local.ports.conferencing.h323.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding, local.tags.proxy]

  allow {
    protocol = "tcp"
    ports    = local.ports.conferencing.h323.tcp
  }

  allow {
    protocol = "udp"
    ports    = local.ports.conferencing.h323.udp
  }
}

# Teams - create for each network
resource "google_compute_firewall" "teams" {
  for_each      = var.services.enable_teams ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-teams-${substr(md5(each.value), 0, 4)}"
  network       = each.value
  description   = local.ports.conferencing.teams.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding]

  allow {
    protocol = "tcp"
    ports    = local.ports.conferencing.teams.tcp
  }

  allow {
    protocol = "udp"
    ports    = local.ports.conferencing.teams.udp
  }
}

# Google Meet - create for each network
resource "google_compute_firewall" "gmeet" {
  for_each      = var.services.enable_gmeet ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-gmeet-${substr(md5(each.value), 0, 4)}"
  network       = each.value
  description   = local.ports.conferencing.gmeet.description
  direction     = "INGRESS"
  source_ranges = local.default_ranges
  target_tags   = [local.tags.transcoding]

  allow {
    protocol = "tcp"
    ports    = local.ports.conferencing.gmeet.tcp
  }

  allow {
    protocol = "udp"
    ports    = local.ports.conferencing.gmeet.udp
  }
}

# =============================================================================
# Internal Node Communication
# =============================================================================

# Allow IPsec communication between nodes (IKE and ESP)
resource "google_compute_firewall" "internal_node" {
  for_each = data.google_compute_network.networks

  name    = format("%s-internal-%s", local.firewall_prefix, substr(sha256(each.key), 0, 4))
  network = each.value.name
  project = var.project_id

  description = local.ports.internal.description

  source_tags = [local.tags.management, local.tags.transcoding, local.tags.proxy]
  target_tags = [local.tags.management, local.tags.transcoding, local.tags.proxy]

  # Allow ISAKMP (IKE) for IPsec key exchange
  allow {
    protocol = "udp"
    ports    = local.ports.internal.udp
  }

  # Allow ESP (protocol 50) for IPsec data
  allow {
    protocol = "esp"
  }
}
