# VPC Network
resource "google_compute_network" "pexip_infinity_network" {
  name                    = var.network_config.name
  auto_create_subnetworks = false
  routing_mode            = var.network_config.routing_mode
}

# Subnets (one per region)
resource "google_compute_subnetwork" "pexip_subnets" {
  for_each      = var.regions
  name          = "${var.network_config.name}-subnet-${each.key}"
  ip_cidr_range = each.value.cidr
  network       = google_compute_network.pexip_infinity_network.id
  region        = each.key
}

# Management Node Firewall Rules
resource "google_compute_firewall" "allow_management" {
  name    = "${var.network_config.name}-allow-management"
  network = google_compute_network.pexip_infinity_network.name

  source_ranges = var.network_config.management_allowed_cidrs
  target_tags   = var.firewall_rules.management.tags

  allow {
    protocol = var.firewall_rules.management.protocol
    ports    = var.firewall_rules.management.ports
  }

  dynamic "allow" {
    for_each = var.enable_ssh ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["22"]
    }
  }

  priority = var.firewall_rules.management.priority
}

# Conference Node Firewall Rules (Transcoding)
resource "google_compute_firewall" "allow_conference_transcoding" {
  name    = "${var.network_config.name}-allow-conference-transcoding"
  network = google_compute_network.pexip_infinity_network.name

  source_ranges = var.network_config.conference_allowed_cidrs
  target_tags   = var.firewall_rules.conference_transcoding.tags

  # TCP Rules
  allow {
    protocol = var.firewall_rules.conference_transcoding.protocol
    ports    = var.firewall_rules.conference_transcoding.ports
  }

  # UDP Rules
  allow {
    protocol = var.firewall_rules.conference_transcoding_udp.protocol
    ports    = var.firewall_rules.conference_transcoding_udp.ports
  }

  priority = var.firewall_rules.conference_transcoding.priority
}

# Conference Node Firewall Rules (Proxy)
resource "google_compute_firewall" "allow_conference_proxy" {
  name    = "${var.network_config.name}-allow-conference-proxy"
  network = google_compute_network.pexip_infinity_network.name

  source_ranges = var.network_config.conference_allowed_cidrs
  target_tags   = var.firewall_rules.conference_proxy.tags

  # TCP Rules
  allow {
    protocol = var.firewall_rules.conference_proxy.protocol
    ports    = var.firewall_rules.conference_proxy.ports
  }

  # UDP Rules
  allow {
    protocol = var.firewall_rules.conference_proxy_udp.protocol
    ports    = var.firewall_rules.conference_proxy_udp.ports
  }

  priority = var.firewall_rules.conference_proxy.priority
}

# Internal Communication Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_config.name}-allow-internal"
  network = google_compute_network.pexip_infinity_network.name

  source_tags = var.firewall_rules.internal.tags
  target_tags = var.firewall_rules.internal.tags

  allow {
    protocol = var.firewall_rules.internal.protocol
  }

  priority = var.firewall_rules.internal.priority
}

# Core protocols for Conference Nodes
resource "google_compute_firewall" "allow_protocols" {
  name    = "pexip-allow-protocols"
  network = google_compute_network.pexip_infinity_network.name

  # H.323 TCP
  dynamic "allow" {
    for_each = var.enable_protocols.h323 ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["1720", "33000-39999"]
    }
  }

  # H.323 UDP
  dynamic "allow" {
    for_each = var.enable_protocols.h323 ? [1] : []
    content {
      protocol = "udp"
      ports    = ["1719", "33000-39999"]
    }
  }

  # SIP TCP
  dynamic "allow" {
    for_each = var.enable_protocols.sip ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["5060", "5061", "40000-49999"]
    }
  }

  # SIP UDP
  dynamic "allow" {
    for_each = var.enable_protocols.sip ? [1] : []
    content {
      protocol = "udp"
      ports    = ["5060", "40000-49999"]
    }
  }

  # WebRTC
  dynamic "allow" {
    for_each = var.enable_protocols.webrtc ? [1] : []
    content {
      protocol = "udp"
      ports    = ["40000-49999"]
    }
  }

  source_ranges = var.service_cidrs.conf_services
  target_tags   = ["pexip-conference"]
}

# Conference Node services
resource "google_compute_firewall" "allow_conf_services" {
  name    = "pexip-allow-mgmt-services"
  network = google_compute_network.pexip_infinity_network.name

  dynamic "allow" {
    for_each = var.conf_node_services.one_touch_join ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["443"]
    }
  }

  dynamic "allow" {
    for_each = var.conf_node_services.event_sink ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["80", "443"]
    }
  }

  dynamic "allow" {
    for_each = var.conf_node_services.epic ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["443"]
    }
  }

  source_ranges = var.service_cidrs.conf_services
  target_tags   = ["pexip-conference"]
}

# Shared services for all nodes
resource "google_compute_firewall" "allow_shared_services" {
  name    = "pexip-allow-shared-services"
  network = google_compute_network.pexip_infinity_network.name

  # Required services
  allow {
    protocol = "tcp"
    ports    = ["53", "443"] # DNS, License server
  }

  allow {
    protocol = "udp"
    ports    = ["53", "123"] # DNS, NTP
  }

  # Optional services
  dynamic "allow" {
    for_each = var.shared_services.snmp ? [1] : []
    content {
      protocol = "udp"
      ports    = ["161"]
    }
  }

  dynamic "allow" {
    for_each = var.shared_services.syslog ? [1] : []
    content {
      protocol = "udp"
      ports    = [tostring(var.service_ports.syslog)]
    }
  }

  dynamic "allow" {
    for_each = var.shared_services.web_proxy ? [1] : []
    content {
      protocol = "tcp"
      ports    = [tostring(var.service_ports.web_proxy)]
    }
  }

  source_ranges = var.service_cidrs.shared_services
  target_tags   = ["pexip-management", "pexip-conference"]
}

# Static Internal IP for Management Node
resource "google_compute_address" "mgmt_internal_ip" {
  name         = "pexip-mgmt-internal-ip"
  subnetwork   = google_compute_subnetwork.pexip_subnets[local.primary_region].id
  address_type = "INTERNAL"
  region       = local.primary_region
  purpose      = "GCE_ENDPOINT"
}

# Optional Static External IP for Management Node
resource "google_compute_address" "mgmt_external_ip" {
  count        = var.network_config.enable_public_ips ? 1 : 0
  name         = "pexip-mgmt-external-ip"
  region       = local.primary_region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# Static Internal IPs for Conference Nodes
resource "google_compute_address" "conf_internal_ips" {
  for_each = {
    for pair in flatten([
      for region, config in var.regions : flatten([
        # Transcoding nodes
        [
          for i in range(config.conference_nodes.transcoding.count) : {
            region = region
            index  = i
            type   = "transcoding"
          }
        ],
        # Proxy nodes if configured
        config.conference_nodes.proxy != null ? [
          for i in range(config.conference_nodes.proxy.count) : {
            region = region
            index  = i
            type   = "proxy"
          }
        ] : []
      ])
    ]) : "${pair.region}-${pair.type}-${pair.index}" => pair
  }

  name         = "pexip-conf-${each.value.type}-${each.value.region}-${each.value.index + 1}-internal-ip"
  subnetwork   = google_compute_subnetwork.pexip_subnets[each.value.region].id
  address_type = "INTERNAL"
  region       = each.value.region
  purpose      = "GCE_ENDPOINT"
}

# Optional Static External IPs for Conference Nodes
resource "google_compute_address" "conf_external_ips" {
  for_each = var.network_config.enable_public_ips ? {
    for pair in flatten([
      for region, config in var.regions : flatten([
        # Transcoding nodes
        [
          for i in range(config.conference_nodes.transcoding.count) : {
            region = region
            index  = i
            type   = "transcoding"
          }
        ],
        # Proxy nodes if configured
        config.conference_nodes.proxy != null ? [
          for i in range(config.conference_nodes.proxy.count) : {
            region = region
            index  = i
            type   = "proxy"
          }
        ] : []
      ])
    ]) : "${pair.region}-${pair.type}-${pair.index}" => pair
  } : {}

  name         = "pexip-conf-${each.value.type}-${each.value.region}-${each.value.index + 1}-external-ip"
  region       = each.value.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
