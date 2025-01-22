# This project is for community use. This is not an official Pexip repo.

# Pexip Infinity on GCP using Terraform

Terraform module for deploying Pexip Infinity video conferencing platform on GCP. This module will deploy the Pexip infrastructure, but still requires configuration after deployment.

## Overview

This repository provides Terraform templates for deploying and managing Pexip Infinity video conferencing infrastructure on GCP. The templates are designed to provide a flexible, easy-to-use experience with sensible defaults and comprehensive configuration options.

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
├── modules/         # Modular components
│   ├── apis/        # GCP API enablement
│   ├── images/      # Pexip image management
│   ├── network/     # Networking and firewall rules
│   └── nodes/       # Node configuration (management, transcoding, proxy)
└── terraform.tfvars.example  # Example configuration file
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

2. Copy and modify the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Configure your deployment in terraform.tfvars:
   - Set your GCP project ID and network configuration
   - Configure regions and optional CIDR blocks:
     ```hcl
     deployment_regions = {
       "us-central1" = {
         subnet_name = "subnet-central"  # Required for existing networks
         cidr_block  = "10.0.1.0/24"    # Optional for new networks
       }
       "us-east1" = {
         subnet_name = "subnet-east"
         cidr_block  = "10.0.2.0/24"
       }
     }
     ```
   - Set image configuration:
     ```hcl
     pexip_images = {
       upload_files = true
       management = {
         source_file = "/path/to/files/Pexip_Infinity_v36_GCP_pxMgr.tar.gz"
         image_name  = "pexip-infinity-mgmt-36"
       }
       transcoding = {
         source_file = "/path/to/files/Pexip_Infinity_v36_GCP_pxConf.tar.gz"
         image_name  = "pexip-infinity-transcoding-36"
       }
       proxy = {
         source_file = "/path/to/files/Pexip_Infinity_v36_GCP_pxConf.tar.gz"
         image_name  = "pexip-infinity-proxy-36"
       }
     }
     ```
   - Configure nodes:
     ```hcl
     # Management node
     management_node = {
       region       = "us-central1"
       machine_type = "n2-highcpu-4"
       public_ip    = true
     }

     # Transcoding nodes
     transcoding_nodes = {
       regional_config = {
         "us-central1" = {
           node_count   = 2
           machine_type = "n2-highcpu-8"
         }
         "us-east1" = {
           node_count   = 2
           machine_type = "n2-highcpu-4"
         }
       }
       public_ip = true
     }

     # Optional proxy nodes
     proxy_nodes = {
       regional_config = {
         "us-central1" = {
           node_count   = 1
           machine_type = "n2-highcpu-4"
         }
       }
       public_ip = true
     }
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

See `terraform.tfvars.example` for detailed descriptions and examples.

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
