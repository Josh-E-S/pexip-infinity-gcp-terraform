# VPC Network
resource "google_compute_network" "pexip_infinity_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

# Subnets (one per region)
resource "google_compute_subnetwork" "pexip_subnets" {
  for_each      = var.subnet_cidr_ranges
  name          = "pexip-subnet-${each.key}"
  ip_cidr_range = each.value
  network       = google_compute_network.pexip_infinity_network.id
  region        = each.key
}

# Firewall rule for internal communication between nodes
resource "google_compute_firewall" "allow_internal" {
  name    = "pexip-allow-internal"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
    ports    = ["500"]
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "esp"
  }

  source_ranges = values(var.subnet_cidr_ranges)
  target_tags   = ["pexip-conf-node"]
}

# Firewall rule for Management Node access
resource "google_compute_firewall" "allow_management" {
  name    = "pexip-allow-management"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = "tcp"
    ports    = ["443", "22"] # HTTPS and SSH
  }

  source_ranges = var.management_allowed_cidrs
  target_tags   = ["pexip-management"]
}

# Firewall rule for Conference Node provisioning
resource "google_compute_firewall" "allow_provisioning" {
  name    = "pexip-allow-provisioning"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = "tcp"
    ports    = ["8443"] # Conference Node provisioning port
  }

  source_ranges = var.management_allowed_cidrs
  target_tags   = ["pexip-conf-node"]
}

# Firewall rule for Conference Node access
resource "google_compute_firewall" "allow_conferencing" {
  name    = "pexip-allow-conferencing"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = "tcp"
    ports = [
      "443",  # HTTPS
      "1720", # H.323/Q.931
      "5060", # SIP
      "5061", # SIP/TLS
      # "33000-39999",  # TCP H.323 Media Optional
      # "40000-49999"   # SIP TCP Media Optional
    ]
  }

  allow {
    protocol = "udp"
    ports = [
      "1719",        # H.323/RAS
      "33000-39999", # H.323 Media
      "40000-49999"  # SIP/WebRTC Media
    ]
  }

  source_ranges = var.conf_node_allowed_cidrs
  target_tags   = ["pexip-conf-node"]
}

# Static Internal IP for Management Node
resource "google_compute_address" "mgmt_internal_ip" {
  name         = "pexip-mgmt-internal-ip"
  subnetwork   = google_compute_subnetwork.pexip_subnets[var.default_region].id
  address_type = "INTERNAL"
  region       = var.default_region
  purpose      = "GCE_ENDPOINT"
}

# Optional Static External IP for Management Node
resource "google_compute_address" "mgmt_external_ip" {
  count        = var.enable_public_ips ? 1 : 0
  name         = "pexip-mgmt-external-ip"
  region       = var.default_region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# Static Internal IPs for Conference Nodes using a map
resource "google_compute_address" "conf_internal_ips" {
  for_each = {
    for idx in flatten([
      for region, count in var.conf_node_count : [
        for i in range(count) : {
          region = region
          index  = i
        }
      ]
    ]) : "${idx.region}-${idx.index}" => idx
  }

  name         = "pexip-conf-internal-ip-${each.value.region}-${each.value.index + 1}"
  subnetwork   = google_compute_subnetwork.pexip_subnets[each.value.region].id
  address_type = "INTERNAL"
  region       = each.value.region
  purpose      = "GCE_ENDPOINT"
}

# Optional Static External IPs for Conference Nodes using a map
resource "google_compute_address" "conf_external_ips" {
  for_each = var.enable_public_ips ? {
    for idx in flatten([
      for region, count in var.conf_node_count : [
        for i in range(count) : {
          region = region
          index  = i
        }
      ]
    ]) : "${idx.region}-${idx.index}" => idx
  } : {}

  name         = "pexip-conf-external-ip-${each.value.region}-${each.value.index + 1}"
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}