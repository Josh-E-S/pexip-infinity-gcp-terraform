locals {
  # =============================================================================
  # Node Configurations
  # =============================================================================

  # Transcoding node configurations
  transcoding_nodes = merge([
    for pool_name, pool in var.transcoding_node_pools : [
      for zone in var.regions[pool.region].zones : [
        for idx in range(pool.count_per_zone) : {
          "${pool_name}-${zone}-${idx + 1}" = {
            name         = "${var.transcoding_node_name}-${pool_name}-${idx + 1}"
            region       = pool.region
            zone         = zone
            machine_type = pool.machine_type
            disk_size    = pool.disk_size
            disk_type    = pool.disk_type
            public_ip    = pool.public_ip
            static_ip    = pool.static_ip
          }
        }
      ]
    ]
  ])

  # Proxy node configurations
  proxy_nodes = merge([
    for pool_name, pool in var.proxy_node_pools : [
      for zone in var.regions[pool.region].zones : [
        for idx in range(pool.count_per_zone) : {
          "${pool_name}-${zone}-${idx + 1}" = {
            name      = "${var.proxy_node_name}-${pool_name}-${idx + 1}"
            region    = pool.region
            zone      = zone
            public_ip = pool.public_ip
            static_ip = pool.static_ip
          }
        }
      ]
    ]
  ])

  # Process transcoding node configurations
  transcoding_node_configs = {
    for name, node in local.transcoding_nodes : name => {
      tags = distinct(concat(
        [var.transcoding_node_name],
        [for protocol, enabled in var.transcoding_services.enable_protocols : "${var.transcoding_node_name}-${protocol}" if enabled]
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
        [var.proxy_node_name],
        [for protocol, enabled in var.proxy_services.enable_protocols : "${var.proxy_node_name}-${protocol}" if enabled]
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
}
