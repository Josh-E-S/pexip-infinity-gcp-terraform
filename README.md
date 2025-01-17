# Terraform Pexip Infinity for GCP

Infrastructure as Code templates for deploying Pexip Infinity video conferencing platform on Google Cloud Platform (GCP).

## Overview

This repository contains Terraform templates for deploying and managing Pexip Infinity video conferencing infrastructure on GCP. The templates are designed to provide a flexible, secure, and maintainable deployment process.

### Features

- Single management node deployment with configurable services
- Multi-region transcoding node support
- Optional proxy node deployment
- Customizable instance configurations
- Production-ready security settings
- Fine-grained service access control
- Comprehensive documentation

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
git clone https://github.com/Josh-E-S/terraform-pexip-infinity.git
cd terraform-pexip-infinity/gcp
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

## Configuration Options

### Required Configuration

- `project_id` - Your GCP project ID
- `network_name` - Existing VPC network name
- `regions` - Map of regions with subnet names and zones
- `pexip_images` - Management and conference node image configuration

### Node Configuration

#### Management Node
- Configurable machine type and disk
- Service enable/disable flags for:
  - SSH access
  - Directory (LDAP) access
  - SMTP access
  - Syslog access
- CIDR-based access control

#### Transcoding Nodes
- Multiple pool support
- Region and zone placement
- Configurable machine types
- Public IP and static IP options
- Protocol and service configuration

#### Proxy Nodes (Optional)
- Can be disabled by setting count = 0
- Not recommended for cloud deployments
- Only needed for specific network requirements

### Security Features

- SSH key management via Secret Manager
- Firewall rules with CIDR-based access control
- Service-specific access controls
- Secure defaults with option to customize

## File Structure

```
gcp/
├── apis.tf           # API enablement
├── conference_nodes.tf # Conferencing node configuration
├── images.tf         # Image management
├── locals.tf         # Local variables
├── main.tf          # Main configuration
├── management_node.tf # Management node configuration
├── network.tf       # Network and firewall rules
├── outputs.tf       # Output definitions
├── ssh.tf          # SSH key management
├── variables.tf    # Variable definitions
└── versions.tf     # Version constraints
```

## Maintenance

To modify your deployment:

1. Update your terraform.tfvars file
2. Run terraform plan to review changes
3. Apply changes with terraform apply

To destroy the deployment:
```bash
terraform destroy
```

## Support

For issues and feature requests, please open an issue on GitHub.
