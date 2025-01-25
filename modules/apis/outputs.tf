# =============================================================================
# APIs Module Outputs
# =============================================================================

output "enabled_apis" {
  description = "Enabled GCP APIs"
  value       = google_project_service.apis
}
