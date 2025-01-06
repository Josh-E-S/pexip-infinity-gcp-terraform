locals {
  # =============================================================================
  # Network Processing
  # =============================================================================
  
  # Process subnet configurations
  subnet_configs = var.auto_generate_subnets ? {
    for idx, region in keys(var.transcoding_nodes) :
    region => {
      cidr = cidrsubnet(
        var.network_cidr_base,
        var.network_subnet_size - split("/", var.network_cidr_base)[1],
        var.network_subnet_start + idx
      )
    }
  } : var.manual_subnet_cidrs

  # =============================================================================
  # Node Type Tags
  # =============================================================================
  
  # Base tags for different node types
  base_tags = {
    management  = ["pexip", "pexip-management"]
    transcoding = ["pexip", "pexip-conference", "pexip-transcoding"]
    proxy      = ["pexip", "pexip-conference", "pexip-proxy"]
  }

  # Generate protocol-specific tags based on enabled protocols
  protocol_tags = {
    for node_type, nodes in {
      "transcoding" = var.transcoding_nodes
      "proxy"       = var.proxy_nodes
    } : node_type => distinct(flatten([
      for name, node in nodes : [
        node.enable_protocols.sip ? "pexip-sip" : [],
        node.enable_protocols.h323 ? "pexip-h323" : [],
        node.enable_protocols.webrtc ? "pexip-webrtc" : [],
        node.enable_protocols.teams ? "pexip-teams" : [],
        node.enable_protocols.gmeet ? "pexip-gmeet" : []
      ]
    ]))
  }

  # =============================================================================
  # Firewall Rules Generation
  # =============================================================================

  # Management Node Firewall Rules
  mgmt_node_firewall_rules = {
    # Admin UI and SSH access
    admin = {
      name        = "pexip-mgmt-admin"
      description = "Management node administrative access"
      direction   = "INGRESS"
      source_ranges = concat(
        var.mgmt_node.allowed_cidrs.admin_ui,
        var.mgmt_node.allowed_cidrs.ssh
      )
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443", "22"]
        }
      ]
      target_tags = local.base_tags.management
    }

    # Optional services (LDAP, SMTP, Syslog)
    services = {
      name        = "pexip-mgmt-services"
      description = "Management node optional services"
      direction   = "INGRESS"
      source_ranges = distinct(concat(
        var.mgmt_node.service_cidrs.directory,
        var.mgmt_node.service_cidrs.smtp,
        var.mgmt_node.service_cidrs.syslog
      ))
      allow = [
        {
          protocol = "tcp"
          ports    = ["389", "636", "3268", "3269", "587"]
        },
        {
          protocol = "udp"
          ports    = ["514"]
        }
      ]
      target_tags = local.base_tags.management
    }
  }

  # Conference Node Common Firewall Rules
  conference_node_common_rules = {
    # Core media services
    media = {
      name        = "pexip-conference-media"
      description = "Conference node media traffic"
      direction   = "INGRESS"
      source_ranges = var.conference_node_defaults.core_service_cidrs.media
      allow = [
        {
          protocol = "udp"
          ports    = ["${var.service_ports.core.media.udp_range.start}-${var.service_ports.core.media.udp_range.end}"]
        }
      ]
      target_tags = ["pexip-conference"]
    }

    # Internal communication
    internal = {
      name        = "pexip-internal"
      description = "Inter-node communication"
      direction   = "INGRESS"
      source_ranges = var.conference_node_defaults.core_service_cidrs.internal
      allow = [
        {
          protocol = "udp"
          ports    = ["500"]
        },
        {
          protocol = "esp"
        }
      ]
      target_tags = ["pexip"]
    }
  }

  # Protocol-Specific Firewall Rules
  protocol_firewall_rules = {
    sip = {
      name        = "pexip-sip"
      description = "SIP signaling"
      allow = [
        {
          protocol = "tcp"
          ports    = var.service_ports.core.sip.tcp
        },
        {
          protocol = "udp"
          ports    = var.service_ports.core.sip.udp
        }
      ]
      target_tags = ["pexip-sip"]
    }
    h323 = {
      name        = "pexip-h323"
      description = "H.323 signaling"
      allow = [
        {
          protocol = "tcp"
          ports    = var.service_ports.core.h323.tcp
        },
        {
          protocol = "udp"
          ports    = var.service_ports.core.h323.udp
        }
      ]
      target_tags = ["pexip-h323"]
    }
    webrtc = {
      name        = "pexip-webrtc"
      description = "WebRTC access"
      allow = [
        {
          protocol = "tcp"
          ports    = var.service_ports.core.webrtc.tcp
        }
      ]
      target_tags = ["pexip-webrtc"]
    }
    teams = {
      name        = "pexip-teams"
      description = "Microsoft Teams integration"
      allow = [
        {
          protocol = "tcp"
          ports    = var.service_ports.teams.tcp
        },
        {
          protocol = "udp"
          ports    = ["${var.service_ports.teams.udp_range.start}-${var.service_ports.teams.udp_range.end}"]
        }
      ]
      target_tags = ["pexip-teams"]
    }
  }

  # Service-Specific Firewall Rules
  service_firewall_rules = {
    turn = {
      name        = "pexip-turn"
      description = "TURN server access"
      allow = [
        {
          protocol = "udp"
          ports    = var.service_ports.turn.udp
        }
      ]
      target_tags = ["pexip-proxy"]
    }
    rtmp = {
      name        = "pexip-rtmp"
      description = "RTMP streaming"
      allow = [
        {
          protocol = "tcp"
          ports    = var.service_ports.rtmp.tcp
        }
      ]
      target_tags = ["pexip-proxy"]
    }
  }

  # =============================================================================
  # Node Configuration Processing
  # =============================================================================

  # Process transcoding node configurations
  transcoding_node_configs = {
    for name, node in var.transcoding_nodes : name => merge(node, {
      tags = distinct(concat(
        local.base_tags.transcoding,
        local.protocol_tags.transcoding,
        [
          node.enable_protocols.sip ? "pexip-sip" : "",
          node.enable_protocols.h323 ? "pexip-h323" : "",
          node.enable_protocols.webrtc ? "pexip-webrtc" : "",
          node.enable_protocols.teams ? "pexip-teams" : "",
          node.enable_protocols.gmeet ? "pexip-gmeet" : ""
        ]
      ))
      metadata = {
        node-type = "transcoding"
        protocols = jsonencode(node.enable_protocols)
        services  = jsonencode(node.enable_services)
      }
    })
  }

  # Process proxy node configurations
  proxy_node_configs = {
    for name, node in var.proxy_nodes : name => merge(node, {
      tags = distinct(concat(
        local.base_tags.proxy,
        local.protocol_tags.proxy,
        [
          node.enable_protocols.sip ? "pexip-sip" : "",
          node.enable_protocols.h323 ? "pexip-h323" : "",
          node.enable_protocols.webrtc ? "pexip-webrtc" : "",
          node.enable_protocols.teams ? "pexip-teams" : "",
          node.enable_protocols.gmeet ? "pexip-gmeet" : ""
        ]
      ))
      metadata = {
        node-type = "proxy"
        protocols = jsonencode(node.enable_protocols)
        services  = jsonencode(node.enable_services)
      }
    })
  }

  # =============================================================================
  # System Configuration Processing
  # =============================================================================

  # Process system service configurations
  system_configs = {
    dns_config = {
      servers = var.dns_servers
      cidrs   = var.system_service_cidrs.dns
    }
    ntp_config = {
      servers = var.ntp_servers
      cidrs   = var.system_service_cidrs.ntp
    }
  }
}
