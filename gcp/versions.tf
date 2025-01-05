terraform {
  # Terraform version constraint
  required_version = ">= 1.0.0"

  required_providers {
    # Google Provider
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0, < 7.0.0"  # Allows 4.x and 5.x and 6.x versions
    }

    # Random provider for generating unique identifiers
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }

    # TLS provider for any certificate operations
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }

    # Time provider for creating delays or timestamps
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = local.primary_region
}
