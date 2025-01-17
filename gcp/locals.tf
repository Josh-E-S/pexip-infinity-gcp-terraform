locals {
  # =============================================================================
  # Default Node Configurations
  # =============================================================================
  default_node_config = {
    transcoding = {
      machine_type = "n2-standard-4"
      disk_size    = 50
      disk_type    = "pd-standard"
    }
    proxy = {
      machine_type = "n2-standard-4"
      disk_size    = 50
      disk_type    = "pd-standard"
    }
  }

  # =============================================================================
  # Node Configurations
  # =============================================================================

  # Management node configuration
  mgmt_node_config = {
    tags     = [var.mgmt_node_name]
    metadata = {}
  }

  # Transcoding node configurations
  transcoding_nodes = merge(flatten([
    for pool_name, pool in var.transcoding_node_pools : [
      for i in range(pool.count) : {
        "${pool_name}-${pool.zone}-${format("%d", i + 1)}" = {
          name         = "${var.transcoding_node_name}-${pool_name}-${format("%d", i + 1)}"
          region       = pool.region
          zone         = pool.zone
          machine_type = pool.machine_type
          disk_size    = pool.disk_size
          disk_type    = pool.disk_type
          public_ip    = pool.public_ip
          static_ip    = pool.static_ip
        }
      }
    ]
  ])...)

  # Proxy node configurations
  proxy_nodes = merge(flatten([
    for pool_name, pool in var.proxy_node_pools : [
      for i in range(pool.count) : {
        "${pool_name}-${pool.zone}-${format("%d", i + 1)}" = {
          name         = "${var.proxy_node_name}-${pool_name}-${format("%d", i + 1)}"
          region       = pool.region
          zone         = pool.zone
          machine_type = "n2-standard-4"
          public_ip    = pool.public_ip
          static_ip    = pool.static_ip
        }
      }
    ]
  ])...)

  # Process transcoding node configurations
  transcoding_node_configs = {
    for name, node in local.transcoding_nodes : name => {
      tags = distinct(concat(
        [var.transcoding_node_name],
        [for protocol, enabled in var.transcoding_services.enable_protocols : "${var.transcoding_node_name}-${protocol}" if enabled]
      ))
      metadata = {
        node_type = "transcoding"
        node_name = node.name
        region    = node.region
        zone      = node.zone
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
        node_type = "proxy"
        node_name = node.name
        region    = node.region
        zone      = node.zone
      }
    }
  }
}
