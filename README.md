# This project is for community use. This is not an official Pexip repo.

# Terraform Google Pexip Infinity

A Terraform module for deploying Pexip Infinity conferencing platform on Google Cloud. This module handles the infrastructure setup including networks, compute instances, images, and firewall rules, letting you focus on configuring your Pexip environment.

## Overview

This module creates the core infrastructure needed to run Pexip Infinity on Google Cloud:
- Management, transcoding, and optional proxy nodes across multiple regions
- Network configuration with support for both new and existing VPCs
- Firewall rules for Pexip services (SIP, H.323, Teams, Meet)
- Automated image management from local files or existing images
- SSH key generation and secure storage in Secret Manager

### Features

- Multi-region support with automatic CIDR block calculation
- Unified node management for management, transcoding, and proxy nodes
- Static IP support for all nodes (internal and external)
- Flexible network configuration (use existing or create new)
- Comprehensive image management with support for both local files and existing images
- Secure SSH key management through Secret Manager

## Repository Structure

```
.
├── main.tf           # Root configuration and module calls
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── versions.tf       # Provider and version constraints
├── examples/         # Example configurations
│   ├── basic/       # Basic single-region deployment
│   └── advanced/    # Full-featured multi-region deployment
└── modules/         # Modular components
    ├── apis/        # GCP API enablement
    ├── images/      # Pexip image management
    ├── network/     # Networking and firewall rules
    ├── nodes/       # Node configuration (management, transcoding, proxy)
    └── ssh/         # SSH key generation and management
```

## Prerequisites

### Required for Deployment
1. Terraform >= 1.0.0
2. GCP Project with:
   - Required APIs enabled (this module will attempt to enable them)
   - Service Account with necessary permissions
3. For existing network deployment:
   - VPC Network and subnets already created in your target regions
4. Pexip Infinity images from https://www.pexip.com/help-center/platform-download
   - Option 1: Images already uploaded to your GCP project
   - Option 2: Local .tgz files that the module will upload

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/Josh-E-S/terraform-gcp-pexip-infinity.git
cd terraform-gcp-pexip-infinity
```

2. Choose an example configuration:
```bash
# For a basic setup
cd examples/basic
# For a full-featured setup
cd examples/advanced
```

3. Copy and modify the variables file:
```bash
cp terraform.tfvars.sample terraform.tfvars
# Edit terraform.tfvars with your values
```

4. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

## Configuration

### Required Variables

- `project_id`: Your GCP project ID
- `network_config`: Network configuration (existing or new)
- `deployment_regions`: Region and subnet configuration
- `pexip_images`: Configuration for Pexip Infinity images
- `management_node`: Management node configuration
- `transcoding_nodes`: Transcoding node configurations

### Optional Variables

- `proxy_nodes`: Proxy node configurations
- `management_access`: Management access CIDR ranges and features
- `pexip_services`: Service enablement for SIP, H.323, Teams, and Meet

See the `examples/` directory for detailed configuration examples:

1. **Basic Example** (`examples/basic/`)
   - Single region deployment
   - One management node and one transcoding node
   - Minimum required configuration

2. **Advanced Example** (`examples/advanced/`)
   - Multi-region deployment
   - Multiple transcoding and proxy nodes
   - Custom machine types and disk sizes
   - All optional services enabled

## Post-Deployment

After successful deployment, the module will output:
1. SSH key retrieval instructions (if auto-generated)
2. Management node connection details (SSH and web interface)
3. Transcoding and proxy node details per region
4. Network and subnet information

Use these details to:
1. Run the initial installer on the management node
2. Access the management interface to complete Pexip configuration
3. Provision transcoding and proxy nodes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.
