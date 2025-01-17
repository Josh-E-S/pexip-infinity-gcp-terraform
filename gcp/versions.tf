terraform {
  # Terraform version constraint
  required_version = ">= 1.0.0"

  required_providers {
    # Random provider for generating unique identifiers
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }

    # Null provider for precondition checks
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

provider "random" {}
provider "null" {}
