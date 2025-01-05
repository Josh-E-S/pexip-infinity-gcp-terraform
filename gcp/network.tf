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
resource "google_compute_firewall" "mgmt_node_rules" {
  for_each = {
    for name, rule in var.mgmt_node_firewall_rules :
    name => rule
    if rule.enabled
  }

  name    = "${var.network_config.name}-mgmt-${each.key}"
  network = google_compute_network.pexip_infinity_network.name

  dynamic "allow" {
    for_each = length(each.value.tcp_ports) > 0 ? [1] : []
    content {
      protocol = "tcp"
      ports    = [for port in each.value.tcp_ports : tostring(port)]
    }
  }

  dynamic "allow" {
    for_each = length(each.value.udp_ports) > 0 ? [1] : []
    content {
      protocol = "udp"
      ports    = [for port in each.value.udp_ports : tostring(port)]
    }
  }

  target_tags   = var.instance_configs.management.tags
  source_ranges = var.service_cidrs.mgmt_services
}

# Conference Node Firewall Rules
resource "google_compute_firewall" "conference_node_rules" {
  for_each = {
    for name, rule in var.conference_node_firewall_rules :
    name => rule
    if rule.enabled
  }

  name    = "${var.network_config.name}-conf-${each.key}"
  network = google_compute_network.pexip_infinity_network.name

  dynamic "allow" {
    for_each = length(each.value.tcp_ports) > 0 ? [1] : []
    content {
      protocol = "tcp"
      ports    = [for port in each.value.tcp_ports : tostring(port)]
    }
  }

  dynamic "allow" {
    for_each = length(each.value.udp_ports) > 0 ? [1] : []
    content {
      protocol = "udp"
      ports    = [for port in each.value.udp_ports : tostring(port)]
    }
  }

  # Apply to transcoding and/or proxy nodes based on node_types
  target_tags = flatten([
    contains(each.value.node_types, "transcoding") ? var.instance_configs.conference_transcoding.tags : [],
    contains(each.value.node_types, "proxy") ? var.instance_configs.conference_proxy.tags : []
  ])

  source_ranges = var.service_cidrs.conf_services
}

# Media Port Range Rules (special handling for ranges)
resource "google_compute_firewall" "media_ports" {
  count = var.conference_node_firewall_rules.media.enabled ? 1 : 0

  name    = "${var.network_config.name}-media-ports"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = "udp"
    ports    = ["${var.protocol_ports.media.udp_port_range.start}-${var.protocol_ports.media.udp_port_range.end}"]
  }

  target_tags   = concat(var.instance_configs.conference_transcoding.tags, var.instance_configs.conference_proxy.tags)
  source_ranges = var.service_cidrs.conf_services
}

# Internal Network Communication (between nodes)
resource "google_compute_firewall" "internal_communication" {
  name    = "${var.network_config.name}-internal"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = "all"
  }

  source_tags = concat(
    var.instance_configs.management.tags,
    var.instance_configs.conference_transcoding.tags,
    var.instance_configs.conference_proxy.tags
  )
  target_tags = concat(
    var.instance_configs.management.tags,
    var.instance_configs.conference_transcoding.tags,
    var.instance_configs.conference_proxy.tags
  )
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
  for_each = {
    for name, service in var.node_services :
    name => service
    if service.enabled
  }

  name    = "${var.network_config.name}-allow-${each.key}"
  network = google_compute_network.pexip_infinity_network.name

  allow {
    protocol = each.value.protocol
    ports    = [for port in each.value.ports : tostring(port)]
  }

  # Apply to transcoding and/or proxy nodes based on node_types
  target_tags = flatten([
    contains(each.value.node_types, "transcoding") ? var.instance_configs.conference_transcoding.tags : [],
    contains(each.value.node_types, "proxy") ? var.instance_configs.conference_proxy.tags : []
  ])

  source_ranges = var.service_cidrs.conf_services
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
