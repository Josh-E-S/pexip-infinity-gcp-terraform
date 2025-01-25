# This project is for community use. This is not an official Pexip repo.

# Terraform Pexip Infinity Module for Google Cloud Platform (GCP)

A Terraform module for deploying Pexip Infinity conferencing platform on Google Cloud. This module handles the infrastructure setup including networks, compute instances, images, and firewall rules.

## Overview

This module creates the core infrastructure needed to run Pexip Infinity on Google Cloud:
- Management, transcoding, and optional proxy nodes across multiple regions
- Network configuration supporting existing VPCs and subnets
- Firewall rules for Pexip services (SIP, H.323, Teams, Meet)
- Automated image management from local files or existing images
- SSH key generation and secure storage in Secret Manager

### Features

- Multi-region support
- Easy and fast deployment for management, transcoding, and proxy nodes
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

### Required Variables Configuration

1. Project and Network:
   ```hcl
   # GCP project ID where Pexip Infinity will be deployed
   project_id = "your-project-id"

   # Network Configuration - Must have an existing VPC network and subnet
   regions = [{
     region      = "us-central1"     # Primary region for deployment
     network     = "pexip-infinity"  # Name of existing VPC network
     subnet_name = "pexip-subnet"    # Name of existing subnet in the VPC
   }]
   ```

2. Image Configuration:
   ```hcl
   # Option 1: Using existing images from your GCP project
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

3. Node Configuration:
   ```hcl
   # Management Node Configuration
   management_node = {
     name      = "mgmt-1"        # Name prefix for the instance
     region    = "us-central1"   # Must match one of the regions above
     public_ip = true            # Whether to assign a public IP
   }

   # Transcoding Node Configuration
   transcoding_nodes = {
     regional_config = {
       "us-central1" = {
         count     = 1                  # Number of nodes to deploy
         name      = "transcode"        # Name prefix for instances
         public_ip = true               # Whether to assign public IPs
         machine_type = "n2-highcpu-4"  # Machine type based on capacity
       }
     }
   }
   ```

For detailed configuration options, see the [examples](./examples) directory.

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
- `regions`: List of regions with their network configurations
- `pexip_images`: Configuration for Pexip Infinity images (existing or new)
- `management_node`: Management node configuration
- `transcoding_nodes`: Transcoding node configuration

### Optional Variables

- `proxy_nodes`: Proxy node configurations
- `management_access`: Management access CIDR ranges and features (default: `0.0.0.0/0`)
- `services`: Service enablement configuration

See the `examples/` directory for detailed configuration examples:

1. **Basic Example** (`examples/basic/`)
   - Single region deployment
   - One management node and one transcoding node
   - Minimum required configuration

2. **Advanced Example** (`examples/advanced/`)
   - Multi-region deployment
   - Multiple transcoding and proxy nodes
   - Custom machine types
   - All optional services enabled

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
