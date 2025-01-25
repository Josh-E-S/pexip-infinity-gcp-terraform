# ============================================================================
# Network Module - Firewall Rules
# ============================================================================

# Get existing networks and subnets
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

# ============================================================================
# Management Node Firewall Rules
# ============================================================================

# Admin UI Access (HTTPS)
resource "google_compute_firewall" "mgmt_admin" {
  for_each      = toset(local.networks)
  name          = "${local.firewall_prefix}-mgmt-admin-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.management.admin.description
  source_ranges = var.management_access.cidr_ranges
  target_tags   = ["pexip-management"]

  allow {
    protocol = local.ports.management.admin.protocol
    ports    = local.ports.management.admin.ports
  }
}

# SSH Access
resource "google_compute_firewall" "mgmt_ssh" {
  for_each      = var.services.enable_ssh ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-mgmt-ssh-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.management.ssh.description
  source_ranges = var.management_access.cidr_ranges
  target_tags   = ["pexip-management", "pexip-conferencing"]

  allow {
    protocol = local.ports.management.ssh.protocol
    ports    = local.ports.management.ssh.ports
  }
}

# Conferencing Node Provisioning
resource "google_compute_firewall" "mgmt_provisioning" {
  for_each      = var.services.enable_conf_provisioning ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-mgmt-prov-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.management.provisioning.description
  source_ranges = var.management_access.cidr_ranges
  target_tags   = ["pexip-conferencing"]

  allow {
    protocol = local.ports.management.provisioning.protocol
    ports    = local.ports.management.provisioning.ports
  }
}

# ============================================================================
# Call Services Firewall Rules
# ============================================================================

# SIP/SIP-TLS
resource "google_compute_firewall" "sip" {
  for_each      = var.services.enable_sip ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-sip-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.sip.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-conferencing"]

  allow {
    protocol = local.ports.services.sip.protocol
    ports    = local.ports.services.sip.ports
  }
}

# H.323
resource "google_compute_firewall" "h323" {
  for_each      = var.services.enable_h323 ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-h323-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.h323.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-conferencing"]

  allow {
    protocol = local.ports.services.h323.protocol
    ports    = local.ports.services.h323.ports
  }
}

# Microsoft Teams
resource "google_compute_firewall" "teams" {
  for_each      = var.services.enable_teams ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-teams-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.teams.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-conferencing"]

  allow {
    protocol = local.ports.services.teams.protocol
    ports    = local.ports.services.teams.ports
  }
}

# Google Meet
resource "google_compute_firewall" "gmeet" {
  for_each      = var.services.enable_gmeet ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-gmeet-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.gmeet.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-conferencing"]

  allow {
    protocol = local.ports.services.gmeet.protocol
    ports    = local.ports.services.gmeet.ports
  }
}

# ============================================================================
# Optional Services Firewall Rules
# ============================================================================

# Teams Hub
resource "google_compute_firewall" "teams_hub" {
  for_each      = var.services.enable_teams_hub ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-teams-hub-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.teams_hub.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-conferencing"]

  allow {
    protocol = local.ports.services.teams_hub.protocol
    ports    = local.ports.services.teams_hub.ports
  }
}

# Syslog
resource "google_compute_firewall" "syslog" {
  for_each      = var.services.enable_syslog ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-syslog-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.syslog.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-management", "pexip-conferencing"]

  allow {
    protocol = local.ports.services.syslog.protocol
    ports    = local.ports.services.syslog.ports
  }
}

# SMTP
resource "google_compute_firewall" "smtp" {
  for_each      = var.services.enable_smtp ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-smtp-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.smtp.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-management"]

  allow {
    protocol = local.ports.services.smtp.protocol
    ports    = local.ports.services.smtp.ports
  }
}

# LDAP/LDAPS
resource "google_compute_firewall" "ldap" {
  for_each      = var.services.enable_ldap ? toset(local.networks) : []
  name          = "${local.firewall_prefix}-ldap-${substr(md5(each.value), 0, 4)}"
  network       = data.google_compute_network.networks[each.value].name
  project       = var.project_id
  description   = local.ports.services.ldap.description
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pexip-management"]

  allow {
    protocol = local.ports.services.ldap.protocol
    ports    = local.ports.services.ldap.ports
  }
}
