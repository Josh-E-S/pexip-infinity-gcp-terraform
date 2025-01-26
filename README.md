# Pexip Infinity Terraform Module for Google Cloud Platform (GCP)

A Terraform module for deploying Pexip Infinity conferencing platform on Google Cloud. This module handles the infrastructure setup including networking configuration, compute instances, images, and firewall rules.

Note: This module is for community use and not maintained by Pexip.

## Overview

This module creates the core infrastructure needed to run Pexip Infinity on Google Cloud:
- Management, transcoding, and optional proxy nodes across multiple regions
- Network configuration supporting existing VPCs and subnets
- Firewall rules for Pexip services (SIP, H.323, Teams, Google Meet, etc.)
- Automated image management from local files or existing images
- SSH key generation and secure storage in Secret Manager

### Features

- Multi-region support
- Easy and fast deployment for management, transcoding, and proxy nodes
- Simple on/off configuration for various services such as SIP, H.323, Teams, and Google Meet
- Static internal and external IP support for all nodes
- Image management with support for both local files and existing images
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
   - Required APIs enabled (this module will enable them automatically)
   - Service Account with necessary permissions:
     - Compute Admin
     - Secret Manager Admin
     - Service Account User
     - Storage Admin
3. Network Infrastructure:
   - Existing VPC Networks and subnets in your target regions
4. Pexip Infinity images:
   - Option 1: Images already in your GCP project (specify source_image)
   - Option 2: Local .tar.gz files to upload (specify source_file)
   - Pexip Infinity GCP .tar.gz files can be found here on Pexip's website:
     - https://www.pexip.com/help-center/platform-download

### Required Variables Configuration

1. Project and Network:
   ```hcl
   # GCP project ID where Pexip Infinity will be deployed

   project_id = "your-project-id"

   # Network Configuration - Must have an existing VPC network and subnet

   regions = [
     {
       region      = "us-central1"    # Primary region
       network     = "pexip-network"  # VPC network name
       subnet_name = "pexip-subnet-central1"
     },
     {
       region      = "us-east1"       # Secondary region
       network     = "pexip-network"
       subnet_name = "pexip-subnet-east1"
     },
     {
       region      = "europe-west1"   # European region
       network     = "pexip-network"
       subnet_name = "pexip-subnet-europe1"
     }
   ]
   ```

2. Image Configuration Option 1:
   ```hcl
   # Using existing images from your GCP project

   pexip_images = {
     upload_files = false  # Set to false when using existing GCP images
     management = {
       image_name = "pexip-infinity-management-v36"  # Name of existing management node image in GCP
     }
     conferencing = {
       image_name = "pexip-infinity-conferencing-v36"  # Name of existing conferencing node image in GCP
     }
   }
   ```

3. Image Configuration Option 2:
   ```hcl
   # Uploading local Pexip Infinity .tar.gz files with automatic image conversion

   pexip_images = {
     upload_files = true   # Set to true to upload new images
     management = {
       source_file = "/path/to/Pexip_Infinity_Management_Node_v36.tar.gz"
       image_name  = "pexip-infinity-management-v36" # Name to give the image in GCP
     }
     conferencing = {
       source_file = "/path/to/Pexip_Infinity_Conferencing_Node_v36.tar.gz"
       image_name  = "pexip-infinity-conferencing-v36" # Name to give the image in GCP
     }
   }
   ```

4. Management Access Configuration:
   ```hcl
   # Define CIDR ranges that can access management interfaces
   # This includes:
   #  - SSH access (port 22)
   #  - Admin UI (port 443)
   #  - Conferencing Node Provisioning (port 8443)

   management_access = {
     cidr_ranges = [
       "10.0.0.0/8",        # Internal corporate network example
       "192.168.0.0/16",    # VPN network example
       "203.0.113.0/24"     # Office network example
     ]
   }
   ```

5. Management Node Configuration:
   ```hcl
   management_node = {
     name      = "mgmt-1"            # Name prefix for the instance
     region    = "us-central1"       # Region definition- must match one of the regions above
     public_ip = true                # Whether to assign a public IP
     machine_type = "n2-highcpu-4"   # Default recommended by Pexip
   }
   '''

6. Transcoding Node Configuration:
   ```hcl
   # Add addtional transcoding blocks as needed for additional regions and sizes

   transcoding_nodes = {
     regional_config = {
       "us-east1" = {                   # Region definition- must match one of the regions above
         count     = 1                  # Number of nodes to deploy in this region
         name      = "transcode"        # Name prefix for instances
         public_ip = true               # Whether to assign public IPs
         machine_type = "n2-highcpu-8"  # Machine type based on capacity
       }
     }
   }
   ```

1. Proxy Node Configuration (optional)
   ```hcl
   # Add addtional proxy blocks as needed for additional regions and sizes

   proxy_nodes = {
     regional_config = {
       "europe-west1" = {                # Region definition- must match one of the regions above
         count     = 1                   # Number of nodes to deploy in this region
         name      = "proxy"             # Name prefix for the instance
         public_ip = true                # Whether to assign a public IP
         machine_type = "n2-highcpu-4"   # Default recommended by Pexip
       }
     }
   }
   ```

2. Services Configuration (optional):
   ```hcl
   # Create firewall rules for each service as needed. See Pexip's documentation for detailed port information:
   # (https://docs.pexip.com/admin/port_usage.htm)

   services = {
     enable_ssh               = true
     enable_conf_provisioning = true
     enable_sip               = true
     enable_h323              = true
     enable_teams             = true
     enable_gmeet             = true
     enable_teams_hub         = false
     enable_syslog            = false
     enable_smtp              = false
     enable_ldap              = false
   }
   ```

## Quick Start

This module includes comprehensive example configurations to get you started quickly:
- **Basic**: A simple deployment with minimal configuration
- **Advanced**: A full-featured deployment with all available options

Both examples include pre-created `main.tf`, `variables.tf`, `outputs.tf`, and `terraform.tfvars` files. After running `terraform init`, you'll find these examples in `.terraform/modules/pexip-infinity/examples/`.

If you prefer to add the module to your existing Terraform configuration, here's the minimal setup:

```hcl
module "pexip-infinity" {
  source  = "Josh-E-S/pexip-infinity/google"
  version = "x.y.z"

  # Insert required and optional variables here
  # See Configuration section below for details
}
```

To get started:

1. Initialize your Terraform workspace:
   ```bash
   terraform init
   ```

2. Copy and customize an example configuration, or add the module to your existing configuration.

3. Apply the configuration:
   ```bash
   terraform apply
   ```

For detailed configuration options, see the [Configuration](#configuration) section below.

> **Note**: For the latest version number, check the [Terraform Registry](https://registry.terraform.io/modules/Josh-E-S/pexip-infinity/google/latest) or releases page.

## Configuration

### Required Variables

- `project_id`: Your GCP project ID
- `regions`: List of regions with their network configurations
- `pexip_images`: Configuration for Pexip Infinity images (existing or new)
- `management_node`: Management node configuration
- `management_access`: Management access CIDR ranges for SSH, web interface, and provisioning (default: `0.0.0.0/0`)
- `transcoding_nodes`: Transcoding node configuration

### Optional Variables

- `proxy_nodes`: Proxy node configurations
- `services`: Service enablement configuration (default: `enable_sip = true, enable_h323 = true, enable_teams = true, enable_gmeet = true, enable_teams_hub = false, enable_syslog = false, enable_smtp = false, enable_ldap = false`)

See the `examples/` directory for detailed configuration examples:

1. **Basic Example** (`examples/basic/`)
   - Single region deployment
   - One management node and one transcoding node
   - Minimum required configuration

2. **Advanced Example** (`examples/advanced/`)
   - Multi-region deployment
   - Multiple transcoding and proxy nodes
   - Custom machine types
   - All optional services

## Post-Deployment

After successful deployment, the module will output:
1. SSH key retrieval instructions
2. Management node connection details (SSH and web interface)
3. Transcoding and proxy node details per region
4. Network and subnet information
5. Image and disk information

Use these details to:
1. Run the initial installer on the management node
2. Access the management interface to complete Pexip configuration
3. Provision transcoding and proxy nodes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.
