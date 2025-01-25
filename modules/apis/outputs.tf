# =============================================================================
# APIs Module Outputs
# =============================================================================

output "enabled_apis" {
  description = "List of enabled GCP APIs"
  value       = google_project_service.apis
}
