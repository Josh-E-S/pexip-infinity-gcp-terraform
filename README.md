# This project is for community use. This is not an official Pexip repo.

# Pexip Infinity on GCP using Terraform

Terraform module for deploying Pexip Infinity video conferencing platform on GCP. This Module will deploy the Pexip infrastructure, but still requires configuration after deployment.

## Overview

This repository provides Terraform templates for deploying and managing Pexip Infinity video conferencing infrastructure on GCP. The templates are designed to provide a flexible, easy-to-use experience for deploying and managing Pexip Infinity on GCP.

### Features

- Multi-region transcoding node support with region-specific naming (e.g., node-central, node-east)
- Optional proxy node deployment with flexible naming
- Customizable instance configurations (machine types, disk sizes)
- Flexible image management with support for both local files and existing images

## Repository Structure

```
.
├── main.tf           # Root configuration and module calls
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── versions.tf       # Provider and version constraints
├── modules/         # Modular components
│   ├── apis/        # GCP API enablement
│   ├── conference/  # Transcoding and proxy node configuration
│   ├── images/      # Pexip image management
│   ├── management/  # Management node configuration
│   ├── network/     # Networking and firewall rules
│   └── ssh/         # SSH key management
└── terraform.tfvars.example  # Example configuration file
```

## Prerequisites

### Required for Deployment
1. Terraform >= 1.0.0
2. GCP Project with:
   - Required APIs enabled (this module will attempt to enable them)
   - Service Account with necessary permissions
3. VPC Network and subnets already created in your target regions
4. Pexip Infinity Management and Conference node images. These can be downloaded from https://www.pexip.com/help-center/platform-download
   - Option 1: Images already uploaded to your GCP project
   - Option 2: Local .tgz files that the template will upload to a new bucket and create images

### Optional Development Tools
If you plan to contribute to this project, we use the following tools to maintain code quality:
- Pre-commit hooks for code formatting and validation
- TFLint for Terraform linting
- terraform-docs for documentation generation

See the Development Setup section for installation instructions.

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/Josh-E-S/terraform-gcp-pexip-infinity.git
cd terraform-gcp-pexip-infinity
```

2. Copy and modify the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Configure your deployment in terraform.tfvars:
   - Set your GCP project ID and network name
   - Configure regions and subnets:
     ```hcl
     regions = {
       "us-central1" = {
         subnet_name = "subnet-central"  # Must exist in your VPC
         zones       = ["us-central1-a", "us-central1-b"]
       }
       "us-east1" = {
         subnet_name = "subnet-east"     # Must exist in your VPC
         zones       = ["us-east1-b", "us-east1-c"]
       }
       "australia-southeast1" = {
         subnet_name = "subnet-australia" # Must exist in your VPC
         zones       = ["australia-southeast1-a", "australia-southeast1-b"]
       }
     }
     ```
   - Set image configuration:
     ```hcl
     pexip_images = {
       upload_files = false  # Set to true to upload local files
       management = {
         image_name = "pexip-infinity-mgmt-36-manual"  # Use existing image
       }
       conference = {
         image_name = "pexip-infinity-conf-36-manual"  # Use existing image
       }
     }
     ```
   - Configure transcoding and proxy nodes:
     ```hcl
     # Example transcoding node configuration
     transcoding_node_pools = {
       node-central = {
         machine_type = "n2-standard-2"
         disk_size    = 50
         region       = "us-central1"
         zone         = "us-central1-a"
         count        = 1
       }
       node-east = {
         machine_type = "n2-standard-2"
         disk_size    = 50
         region       = "us-east1"
         zone         = "us-east1-b"
         count        = 1
       }
     }

     # Example proxy node configuration
     proxy_node_pools = {
       node = {
         machine_type = "n2-standard-1"
         disk_size    = 50
         region       = "us-central1"
         zone         = "us-central1-a"
         count        = 1
       }
     }
     ```

4. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

## Image Configuration

This module supports two methods for deploying Pexip Infinity images:

1. **Upload Local Files** (First-time deployment):
   - Set `upload_files = true` in your tfvars file
   - Provide paths to your local Pexip Infinity image files:
     - Management Node: `management.source_file`
     - Conference Node: `conference.source_file`
   - The module will:
     - Create a GCS bucket in your project
     - Upload the images to the bucket
     - Create GCE images from the uploaded files

2. **Use Existing Images**:
   - Set `upload_files = false` in your tfvars file
   - Specify the names of existing images in your project:
     - Management Node: `management.image_name`
     - Conference Node: `conference.image_name`
   - The module will use these pre-existing images

Example configuration:
```hcl
# Option 1: Upload local files
pexip_images = {
  upload_files = true
  management = {
    source_file = "/path/to/files/Pexip_Infinity_v36_GCP_pxMgr.tar.gz"
    image_name  = "pexip-infinity-mgmt-36"
  }
  conference = {
    source_file = "/path/to/files/Pexip_Infinity_v36_GCP_pxConf.tar.gz"
    image_name  = "pexip-infinity-conf-36"
  }
}

# Option 2: Use existing images
pexip_images = {
  upload_files = false
  management = {
    image_name = "pexip-infinity-mgmt-36"
  }
  conference = {
    image_name = "pexip-infinity-conf-36"
  }
}
```

## Configuration

### Required Variables

- `project_id`: Your GCP project ID
- `network_name`: Name of your VPC network
- `pexip_images`: Configuration for Pexip Infinity images
- `management_node`: Management node configuration
- `transcoding_node_pools`: Transcoding node pool configurations

See `terraform.tfvars.example` for a complete list of variables and their descriptions.

## Development Setup

This section is only needed if you plan to contribute to this project. It's not required for deploying Pexip Infinity.

### Pre-commit Hooks

This repository uses pre-commit hooks to maintain code quality and consistency. The following hooks are configured:

#### Standard Hooks
- `check-merge-conflict`: Checks for merge conflict strings
- `detect-private-key`: Checks for presence of private keys
- `check-yaml`: Validates YAML files
- `end-of-file-fixer`: Ensures files end with a newline
- `trailing-whitespace`: Trims trailing whitespace

#### Terraform-specific Hooks
- `terraform_fmt`: Automatically formats Terraform code
- `terraform_docs`: Updates Terraform documentation
- `terraform_tflint`: Runs TFLint for additional Terraform checks

To set up pre-commit:

1. Install pre-commit:
   ```bash
   pip install pre-commit
   ```

2. Install the git hooks:
   ```bash
   pre-commit install
   ```

3. (Optional) Run against all files:
   ```bash
   pre-commit run --all-files
   ```

The hooks will run automatically on each commit, ensuring code quality standards are maintained.

## Security

This deployment follows GCP security best practices:
- Least privilege access
- SSH key-based authentication
- Firewall rules for service access control
- Secret management for sensitive data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please open an issue on GitHub.
