# 🚧 Work in Progress 🚧

This project is under active development and only for community use. This is not an official Pexip repo.

# Pexip Infinity on Google Cloud Platform

Infrastructure as Code template for deploying Pexip Infinity video conferencing platform on Google Cloud Platform (GCP).

## Overview

This repository provides Terraform templates for deploying and managing Pexip Infinity video conferencing infrastructure on GCP. The templates are designed to provide a flexible, easy-to-use experience for deploying and managing Pexip Infinity on GCP.

### Features

- Single management node deployment with configurable services
- Multi-region transcoding node support
- Optional proxy node deployment
- Customizable instance configurations
- Production-ready security settings
- Fine-grained service access control
- Comprehensive documentation

## Repository Structure

```
.
├── apis.tf              # GCP API enablement
├── conference_nodes.tf  # Transcoding and proxy node configuration
├── images.tf           # Pexip image management
├── locals.tf          # Local variables and computed values
├── main.tf            # Core infrastructure configuration
├── management_node.tf # Management node configuration
├── network.tf         # Networking and firewall rules
├── outputs.tf         # Output definitions
├── ssh.tf            # SSH key management
├── variables.tf      # Input variable definitions
└── versions.tf       # Provider and version constraints
```

## Prerequisites

Before you begin, ensure you have:

1. Terraform >= 1.0.0
2. GCP Project with:
   - Required APIs enabled (this module will attempt to enable them)
   - Service Account with necessary permissions
3. VPC Network and subnets already created
4. Pexip Infinity images (downloadable from Pexip's website)

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/Josh-E-S/pexip-infinity-gcp-terraform.git
cd pexip-infinity-gcp-terraform
```

2. Copy and modify the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Configure your deployment in terraform.tfvars:
   - Set your GCP project ID and network name
   - Configure regions and zones
   - Set image paths and names
   - Configure node pools and services

4. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
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
