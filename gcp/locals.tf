locals {
  # =============================================================================
  # Node Pool Processing
  # =============================================================================

  # Transform transcoding pools into individual node configurations
  transcoding_nodes = merge(flatten([
    for pool_name, pool in var.transcoding_node_pools : [
      for zone in var.regions[pool.region].zones : [
        for idx in range(pool.count_per_zone) : {
          "${pool_name}-${zone}-${idx + 1}" = {
            name         = "${var.transcoding_node_name}-${pool_name}-${idx + 1}"
            machine_type = pool.machine_type
            disk_size    = pool.disk_size
            disk_type    = pool.disk_type
            region       = pool.region
            zone         = zone
            public_ip    = pool.public_ip
            static_ip    = pool.static_ip
          }
        }
      ]
    ]
  ]))

  # Transform proxy pools into individual node configurations
  proxy_nodes = merge(flatten([
    for pool_name, pool in var.proxy_node_pools : [
      for zone in var.regions[pool.region].zones : [
        for idx in range(pool.count_per_zone) : {
          "${pool_name}-${zone}-${idx + 1}" = {
            name         = "${var.proxy_node_name}-${pool_name}-${idx + 1}"
            region       = pool.region
            zone         = zone
            public_ip    = pool.public_ip
            static_ip    = pool.static_ip
          }
        }
      ]
    ]
  ]))

  # =============================================================================
  # Node Type Tags
  # =============================================================================

  # Base tags for different node types
  base_tags = {
    management  = ["pexip", var.mgmt_node_name]
    transcoding = ["pexip", var.transcoding_node_name]
    proxy       = ["pexip", var.proxy_node_name]
  }

  # Generate protocol-specific tags for transcoding nodes
  transcoding_protocol_tags = [
    var.transcoding_services.enable_protocols.sip ? "pexip-sip" : "",
    var.transcoding_services.enable_protocols.h323 ? "pexip-h323" : "",
    var.transcoding_services.enable_protocols.webrtc ? "pexip-webrtc" : "",
    var.transcoding_services.enable_protocols.teams ? "pexip-teams" : "",
    var.transcoding_services.enable_protocols.gmeet ? "pexip-gmeet" : ""
  ]

  # Generate protocol-specific tags for proxy nodes
  proxy_protocol_tags = [
    var.proxy_services.enable_protocols.sip ? "pexip-sip" : "",
    var.proxy_services.enable_protocols.h323 ? "pexip-h323" : "",
    var.proxy_services.enable_protocols.webrtc ? "pexip-webrtc" : "",
    var.proxy_services.enable_protocols.teams ? "pexip-teams" : "",
    var.proxy_services.enable_protocols.gmeet ? "pexip-gmeet" : ""
  ]

  # =============================================================================
  # Node Configurations
  # =============================================================================

  # Process transcoding node configurations
  transcoding_node_configs = {
    for name, node in local.transcoding_nodes : name => {
      tags = distinct(concat(
        local.base_tags.transcoding,
        [for tag in local.transcoding_protocol_tags : tag if tag != ""]
      ))
      metadata = {
        startup-script = templatefile("${path.module}/templates/conference-node-startup.sh.tpl", {
          node_type = "transcoding"
          node_name = node.name
          region    = node.region
          zone      = node.zone
        })
      }
    }
  }

  # Process proxy node configurations
  proxy_node_configs = {
    for name, node in local.proxy_nodes : name => {
      tags = distinct(concat(
        local.base_tags.proxy,
        [for tag in local.proxy_protocol_tags : tag if tag != ""]
      ))
      metadata = {
        startup-script = templatefile("${path.module}/templates/conference-node-startup.sh.tpl", {
          node_type = "proxy"
          node_name = node.name
          region    = node.region
          zone      = node.zone
        })
      }
    }
  }

  # =============================================================================
  # Service Ports
  # =============================================================================

  # Management node service ports
  mgmt_service_ports = {
    admin = {
      tcp = concat(
        var.mgmt_services.ports.admin_ui.tcp,
        ["22"]  # SSH
      )
    }
    directory = var.mgmt_services.ports.directory
    smtp      = var.mgmt_services.ports.smtp
    syslog    = var.mgmt_services.ports.syslog
  }

  # Transcoding node service ports
  transcoding_service_ports = {
    media = {
      udp = ["${var.transcoding_services.ports.media.udp_range.start}-${var.transcoding_services.ports.media.udp_range.end}"]
    }
    signaling = var.transcoding_services.ports.signaling
    services  = var.transcoding_services.ports.services
  }

  # Proxy node service ports
  proxy_service_ports = {
    media = {
      udp = ["${var.proxy_services.ports.media.udp_range.start}-${var.proxy_services.ports.media.udp_range.end}"]
    }
    signaling = var.proxy_services.ports.signaling
  }
}
