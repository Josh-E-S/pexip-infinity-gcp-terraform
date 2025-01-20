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
data "google_compute_network" "network" {
  name = var.network_name
}

# =============================================================================
# Management Node Firewall Rules
# =============================================================================
resource "google_compute_firewall" "mgmt_admin" {
  depends_on    = [var.apis]
  name          = "allow-mgmt-admin"
  network       = data.google_compute_network.network.name
  description   = "Management node administrative access (Web UI)"
  direction     = "INGRESS"
  source_ranges = var.mgmt_node.allowed_cidrs.admin_ui
  target_tags   = [var.mgmt_node_name]

  allow {
    protocol = "tcp"
    ports    = var.mgmt_services.ports.admin_ui.tcp
  }
}

resource "google_compute_firewall" "mgmt_ssh" {
  count         = var.mgmt_node.services.ssh ? 1 : 0
  depends_on    = [var.apis]
  name          = "pexip-allow-mgmt-ssh"
  network       = data.google_compute_network.network.name
  description   = "Allow SSH access to management node"
  direction     = "INGRESS"
  source_ranges = var.mgmt_node.allowed_cidrs.ssh
  target_tags   = [var.mgmt_node_name]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "mgmt_directory" {
  count         = var.mgmt_node.services.directory ? 1 : 0
  depends_on    = [var.apis]
  name          = "pexip-allow-mgmt-directory"
  network       = data.google_compute_network.network.name
  description   = "Allow directory service access to management node"
  direction     = "INGRESS"
  source_ranges = var.mgmt_node.service_cidrs.directory
  target_tags   = [var.mgmt_node_name]

  allow {
    protocol = "tcp"
    ports    = ["389", "636"] # Both LDAP and LDAPS
  }
}

resource "google_compute_firewall" "mgmt_smtp" {
  count         = var.mgmt_node.services.smtp ? 1 : 0
  depends_on    = [var.apis]
  name          = "pexip-allow-mgmt-smtp"
  network       = data.google_compute_network.network.name
  description   = "Allow SMTP access to management node"
  direction     = "INGRESS"
  source_ranges = var.mgmt_node.service_cidrs.smtp
  target_tags   = [var.mgmt_node_name]

  allow {
    protocol = "tcp"
    ports    = ["25", "587"] # SMTP and Submission
  }
}

resource "google_compute_firewall" "mgmt_syslog" {
  count         = var.mgmt_node.services.syslog ? 1 : 0
  depends_on    = [var.apis]
  name          = "pexip-allow-mgmt-syslog"
  network       = data.google_compute_network.network.name
  description   = "Allow Syslog access to management node"
  direction     = "INGRESS"
  source_ranges = var.mgmt_node.service_cidrs.syslog
  target_tags   = [var.mgmt_node_name]

  allow {
    protocol = "udp"
    ports    = ["514"] # Syslog
  }
}

# =============================================================================
# Conferencing Node Firewall Rules
# =============================================================================

# Media Traffic for Transcoding Nodes
resource "google_compute_firewall" "transcoding_media" {
  depends_on    = [var.apis]
  name          = "allow-transcoding-media"
  network       = data.google_compute_network.network.name
  description   = "Transcoding node media traffic"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.transcoding_node_name]

  allow {
    protocol = "udp"
    ports    = ["${var.transcoding_services.ports.media.udp_range.start}-${var.transcoding_services.ports.media.udp_range.end}"]
  }
}

# Media Traffic for Proxy Nodes
resource "google_compute_firewall" "proxy_media" {
  depends_on    = [var.apis]
  name          = "allow-proxy-media"
  network       = data.google_compute_network.network.name
  description   = "Proxy node media traffic"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.proxy_node_name]

  allow {
    protocol = "udp"
    ports    = ["${var.proxy_services.ports.media.udp_range.start}-${var.proxy_services.ports.media.udp_range.end}"]
  }
}

# Signaling Traffic for All Conference Nodes
resource "google_compute_firewall" "signaling" {
  depends_on    = [var.apis]
  name          = "allow-signaling"
  network       = data.google_compute_network.network.name
  description   = "Conference node signaling traffic"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.transcoding_node_name, var.proxy_node_name]

  dynamic "allow" {
    for_each = {
      sip_tcp  = var.transcoding_services.ports.signaling.sip_tcp
      h323_tcp = var.transcoding_services.ports.signaling.h323_tcp
      webrtc   = var.transcoding_services.ports.signaling.webrtc
    }
    content {
      protocol = "tcp"
      ports    = allow.value
    }
  }

  dynamic "allow" {
    for_each = {
      sip_udp  = var.transcoding_services.ports.signaling.sip_udp
      h323_udp = var.transcoding_services.ports.signaling.h323_udp
    }
    content {
      protocol = "udp"
      ports    = allow.value
    }
  }
}

# Provisioning Access for Conferencing Nodes
resource "google_compute_firewall" "pexip_allow_provisioning" {
  count         = var.conferencing_nodes_provisioning.services.provisioning ? 1 : 0
  depends_on    = [var.apis]
  name          = "pexip-allow-provisioning"
  network       = data.google_compute_network.network.name
  description   = "Allow access to conferencing node provisioning interface"
  direction     = "INGRESS"
  source_ranges = var.conferencing_nodes_provisioning.allowed_cidrs.provisioning
  target_tags   = [var.transcoding_node_name, var.proxy_node_name]

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }
}

# Internal Communication between Nodes
resource "google_compute_firewall" "internal" {
  depends_on  = [var.apis]
  name        = "allow-internal"
  network     = data.google_compute_network.network.name
  description = "Internal communication between Pexip nodes"
  direction   = "INGRESS"
  source_tags = [var.mgmt_node_name, var.transcoding_node_name, var.proxy_node_name]
  target_tags = [var.mgmt_node_name, var.transcoding_node_name, var.proxy_node_name]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

# Optional Services for Transcoding Nodes
resource "google_compute_firewall" "transcoding_services" {
  depends_on    = [var.apis]
  count         = var.transcoding_services.enable_services.one_touch_join || var.transcoding_services.enable_services.event_sink ? 1 : 0
  name          = "allow-transcoding-services"
  network       = data.google_compute_network.network.name
  description   = "Optional services for transcoding nodes"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.transcoding_node_name]

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
