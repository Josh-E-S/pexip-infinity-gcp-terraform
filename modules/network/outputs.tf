# =============================================================================
# Network Module Outputs
# =============================================================================

output "network" {
  description = "Network configuration"
  value       = data.google_compute_network.network
}

output "subnets" {
  description = "Subnet configuration per region"
  value       = data.google_compute_subnetwork.subnets
}

output "tags" {
  description = "Node type tags used for firewall rules"
  value       = local.tags
}

output "firewall_rules" {
  description = "Created firewall rules"
  value = concat(
    # Management access rules
    var.management_access.enable_ssh ? [google_compute_firewall.mgmt_ssh[0].name] : [],
    var.management_access.enable_provisioning ? [google_compute_firewall.mgmt_provisioning[0].name] : [],
    var.services.enable_teams ? [google_compute_firewall.mgmt_teams_hub[0].name] : [],

    # Service rules
    var.services.enable_sip ? [google_compute_firewall.sip[0].name] : [],
    var.services.enable_h323 ? [google_compute_firewall.h323[0].name] : [],
    var.services.enable_teams ? [google_compute_firewall.teams[0].name] : [],
    var.services.enable_gmeet ? [google_compute_firewall.gmeet[0].name] : [],

    # Internal rules
    [google_compute_firewall.internal_udp.name],
    [google_compute_firewall.internal_esp.name]
  )
}
