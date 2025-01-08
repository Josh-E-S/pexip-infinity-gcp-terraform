# =============================================================================
# VPC Network
# =============================================================================
data "google_compute_network" "network" {
  name = var.network_name
}

# =============================================================================
# Subnets
# =============================================================================
data "google_compute_subnetwork" "subnets" {
  for_each = var.regions

  name   = each.value.subnet_name
  region = each.key
}

locals {
  network_id   = data.google_compute_network.network.id
  network_name = data.google_compute_network.network.name

  # Subnet references
  subnet_refs = {
    for region, subnet in data.google_compute_subnetwork.subnets : region => {
      self_link     = subnet.self_link
      ip_cidr_range = subnet.ip_cidr_range
    }
  }
}

# =============================================================================
# Management Node Firewall Rules
# =============================================================================
resource "google_compute_firewall" "mgmt_admin" {
  name          = "pexip-mgmt-admin"
  network       = local.network_name
  description   = "Management node administrative access (Web UI and SSH)"
  direction     = "INGRESS"
  source_ranges = concat(var.mgmt_node.allowed_cidrs.admin_ui, var.mgmt_node.allowed_cidrs.ssh)
  target_tags   = ["${var.mgmt_node_name}"]

  allow {
    protocol = "tcp"
    ports    = var.mgmt_services.ports.admin_ui.tcp
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]  # SSH
  }
}

resource "google_compute_firewall" "mgmt_services" {
  name          = "pexip-mgmt-services"
  network       = local.network_name
  description   = "Management node services (LDAP, SMTP, Syslog)"
  direction     = "INGRESS"
  source_ranges = distinct(concat(
    var.mgmt_node.service_cidrs.directory,
    var.mgmt_node.service_cidrs.smtp,
    var.mgmt_node.service_cidrs.syslog
  ))
  target_tags = ["${var.mgmt_node_name}"]

  dynamic "allow" {
    for_each = {
      directory = var.mgmt_services.ports.directory.tcp
      smtp      = var.mgmt_services.ports.smtp.tcp
      syslog    = var.mgmt_services.ports.syslog.tcp
    }
    content {
      protocol = "tcp"
      ports    = allow.value
    }
  }

  dynamic "allow" {
    for_each = {
      syslog = var.mgmt_services.ports.syslog.udp
    }
    content {
      protocol = "udp"
      ports    = allow.value
    }
  }
}

# =============================================================================
# Conferencing Node Firewall Rules
# =============================================================================

# Media Traffic for Transcoding Nodes
resource "google_compute_firewall" "transcoding_media" {
  name          = "pexip-transcoding-media"
  network       = local.network_name
  description   = "Transcoding node media traffic"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]  # Media traffic needs to be accessible from anywhere
  target_tags   = ["${var.transcoding_node_name}"]

  allow {
    protocol = "udp"
    ports    = ["${var.transcoding_services.ports.media.udp_range.start}-${var.transcoding_services.ports.media.udp_range.end}"]
  }
}

# Media Traffic for Proxy Nodes
resource "google_compute_firewall" "proxy_media" {
  name          = "pexip-proxy-media"
  network       = local.network_name
  description   = "Proxy node media traffic"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]  # Media traffic needs to be accessible from anywhere
  target_tags   = ["${var.proxy_node_name}"]

  allow {
    protocol = "udp"
    ports    = ["${var.proxy_services.ports.media.udp_range.start}-${var.proxy_services.ports.media.udp_range.end}"]
  }
}

# Signaling Traffic for All Conference Nodes
resource "google_compute_firewall" "signaling" {
  name          = "pexip-signaling"
  network       = local.network_name
  description   = "Conference node signaling traffic"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.transcoding_node_name}", "${var.proxy_node_name}"]

  dynamic "allow" {
    for_each = {
      sip_tcp    = var.transcoding_services.ports.signaling.sip_tcp
      h323_tcp   = var.transcoding_services.ports.signaling.h323_tcp
      webrtc     = var.transcoding_services.ports.signaling.webrtc
    }
    content {
      protocol = "tcp"
      ports    = allow.value
    }
  }

  dynamic "allow" {
    for_each = {
      sip_udp    = var.transcoding_services.ports.signaling.sip_udp
      h323_udp   = var.transcoding_services.ports.signaling.h323_udp
    }
    content {
      protocol = "udp"
      ports    = allow.value
    }
  }
}

# Internal Communication between Nodes
resource "google_compute_firewall" "internal" {
  name          = "pexip-internal"
  network       = local.network_name
  description   = "Internal communication between Pexip nodes"
  direction     = "INGRESS"
  source_tags   = ["${var.mgmt_node_name}", "${var.transcoding_node_name}", "${var.proxy_node_name}"]
  target_tags   = ["${var.mgmt_node_name}", "${var.transcoding_node_name}", "${var.proxy_node_name}"]

  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]  # Internal API and configuration
  }
}

# Optional Services for Transcoding Nodes
resource "google_compute_firewall" "transcoding_services" {
  count         = var.transcoding_services.enable_services.one_touch_join || var.transcoding_services.enable_services.event_sink ? 1 : 0
  name          = "pexip-transcoding-services"
  network       = local.network_name
  description   = "Optional services for transcoding nodes"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.transcoding_node_name}"]

  dynamic "allow" {
    for_each = {
      one_touch_join = var.transcoding_services.enable_services.one_touch_join ? var.transcoding_services.ports.services.one_touch_join : []
      event_sink     = var.transcoding_services.enable_services.event_sink ? var.transcoding_services.ports.services.event_sink : []
    }
    content {
      protocol = "tcp"
      ports    = allow.value
    }
  }
}
