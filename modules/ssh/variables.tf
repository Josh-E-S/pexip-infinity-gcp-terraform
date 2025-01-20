variable "project_id" {
  description = "The GCP project ID to deploy to"
  type        = string
}

variable "apis" {
  description = "Enabled APIs from the apis module"
  type = object({
    enabled_apis = map(object({
      id = string
    }))
  })
}
