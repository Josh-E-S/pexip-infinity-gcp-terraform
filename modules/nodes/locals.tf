locals {
  # Default configurations per node type
  node_defaults = {
    management = {
      machine_type   = "n2-highcpu-4"
      boot_disk_size = 100
      instance_count = 1 # Always 1 for management
      network_tags   = ["pexip-mgmt"]
    }
    transcoding = {
      machine_type   = "n2-highcpu-8"
      boot_disk_size = 50
      network_tags   = ["pexip-transcoding"]
    }
    proxy = {
      machine_type   = "n2-highcpu-4"
      boot_disk_size = 50
      network_tags   = ["pexip-proxy"]
    }
  }

  # Use defaults if not specified
  machine_type   = coalesce(var.machine_type, local.node_defaults[var.type].machine_type)
  boot_disk_size = coalesce(var.boot_disk_size, local.node_defaults[var.type].boot_disk_size)

  # Instance count validation
  instance_count = var.type == "management" ? 1 : var.quantity

  # Network tags
  network_tags = local.node_defaults[var.type].network_tags

  # Base labels for all instances
  base_labels = {
    managed_by = "terraform"
    node_type  = var.type
  }

  # Merged labels
  labels = merge(local.base_labels, var.labels)
}
