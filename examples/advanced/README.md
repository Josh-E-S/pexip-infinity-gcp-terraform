Advanced Pexip Infinity Deployment Example
=====================================

This example demonstrates a full-featured, multi-region deployment of Pexip Infinity on Google Cloud Platform (GCP). It creates a management node, multiple transcoding nodes across regions, and proxy nodes for optimal global coverage.

## Quick Start

1. Initialize the module in your Terraform workspace:
   ```bash
   terraform init
   ```

2. Create a new directory for your deployment:
   ```bash
   mkdir pexip-deployment
   cd pexip-deployment
   ```

3. Copy the example files to your deployment directory:
   ```bash
   # Copy from the examples/advanced directory after module initialization
   cp .terraform/modules/*/examples/advanced/* .

   # Rename the tfvars example file
   mv terraform.tfvars.example terraform.tfvars
   ```

4. Update `terraform.tfvars` with your specific values:
   - Set your GCP project ID
   - Configure your network settings for each region
   - Set your management access CIDR ranges
   - Specify your Pexip image names
   - Configure nodes for each region
   - Enable/disable optional services as needed

5. Deploy the infrastructure:
   ```bash
   terraform plan    # Review the changes
   terraform apply   # Deploy the infrastructure
   ```

## Overview

This example creates a comprehensive infrastructure for running Pexip Infinity on Google Cloud:
- Multi-region deployment with enhanced specifications
- Management node with increased resources for larger deployments
- Multiple transcoding nodes across regions for geographic distribution
- Proxy nodes for external call signaling and client connections only
- Automated image creation from local Pexip files
- Complete firewall rules for all Pexip services

### Features

- Multi-region deployment for global coverage
- Enhanced machine specifications for production workloads
- Automated image management from local files
- Complete service enablement including Teams Hub, LDAP, etc.
- Static IP support for all nodes
- Comprehensive firewall rules for all services

## Prerequisites

### Required for Deployment
1. Terraform >= 1.0.0
2. GCP Project with:
   - Required APIs enabled (automatically enabled by the module)
   - Service Account with necessary permissions:
     - Compute Admin
     - Secret Manager Admin
     - Service Account User
     - Storage Admin
3. Network Infrastructure:
   - Existing VPC Network spanning multiple regions
   - Subnets in each target region
4. Pexip Infinity images:
   - This example requires that you download Pexip Infinity images. The module will upload them and convert them to GCP images automatically.
   - Pexip Infinity GCP .tar.gz files can be found on Pexip's website. Both management and conferencing images are required:
     - https://www.pexip.com/help-center/platform-download

### Required Variables Configuration

1. Project and Network:
   ```hcl
   # GCP project ID where Pexip Infinity will be deployed
   project_id = "your-project-id"

   # Network Configuration - Must have existing VPC networks and subnets
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

2. Image Configuration:
   ```hcl
   # Upload and convert Pexip images from local files
   pexip_images = {
     upload_files = true   # Set to true to upload new images
     management = {
       source_file = "/path/to/Pexip_Infinity_Management_Node_v36.tar.gz"  # Full path to local management node image
       image_name  = "pexip-infinity-management-v36"  # Name to give the image in GCP
     }
     conferencing = {
       source_file = "/path/to/Pexip_Infinity_Conferencing_Node_v36.tar.gz"  # Full path to local conferencing node image
       image_name  = "pexip-infinity-conferencing-v36"  # Name to give the image in GCP
     }
   }
   ```

3. Management Access Configuration:
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

4. Node Configuration:
   ```hcl
   # Node names will be automatically formatted as: {name}-{region} for single nodes
   # or {name}-{region}-{index} for multiple nodes (e.g., transcode-us-east1-1)

   # Management Node Configuration
   management_node = {
     name         = "mgmt"            # Will become mgmt-us-central1
     region       = "us-central1"
     public_ip    = true
     machine_type = "n2-highcpu-8"    # Enhanced for larger deployments
     disk_size    = 150               # Larger disk for logs
   }

   # Transcoding Node Configuration
   transcoding_nodes = {
     regional_config = {
       "us-east1" = {
         count        = 2                 # Will create: transcode-us-east1-1, transcode-us-east1-2
         name         = "transcode"       # Base name for instances
         public_ip    = true              # Required for external participants
         machine_type = "n2-highcpu-8"    # Enhanced for production workloads
         disk_size    = 50                # Additional storage for logs
       },
       "europe-west1" = {
         count        = 2                 # Will create: transcode-europe-west1-1, transcode-europe-west1-2
         name         = "transcode"       # Base name for instances
         public_ip    = false             # Internal-only access, proxy nodes required below
         machine_type = "n2-highcpu-8"
         disk_size    = 50
       },
       "asia-southeast1" = {
         count        = 2                 # Will create: transcode-asia-southeast1-1, transcode-asia-southeast1-2
         name         = "transcode"       # Base name for instances
         public_ip    = true              # Required for external participants
         machine_type = "n2-highcpu-8"    # Enhanced for production workloads
         disk_size    = 50                # Additional storage for logs
       }
     }
   }

   # Proxy Node Configuration
   proxy_nodes = {
     regional_config = {
       "europe-west1" = {
         count        = 2                # Will create: proxy-europe-west1-1, proxy-europe-west1-2
         name         = "proxy"          # Base name for instances
         public_ip    = true             # Required for external participants
         machine_type = "n2-highcpu-4"   # Standard proxy specification
         disk_size    = 50               # Additional storage for logs
       }
     }
   }
   ```

### Optional Variables Configuration

1. Services Configuration:
   ```hcl
   # Service configuration toggles for firewall rules
   services = {
     # Management services
     enable_ssh               = true    # SSH access (port 22)
     enable_conf_provisioning = true    # Conferencing Node Provisioning (port 8443)

     # Call services
     enable_sip   = true    # SIP signaling and media
     enable_h323  = true    # H.323 signaling and media
     enable_teams = true    # Microsoft Teams media
     enable_gmeet = true    # Google Meet media

     # Optional services (all enabled for full deployment)
     enable_teams_hub = true    # Microsoft Teams hub
     enable_syslog    = true    # Syslog
     enable_smtp      = true    # SMTP
     enable_ldap      = true    # LDAP
   }
   ```

## Quick Start

To use this example:

1. Initialize your Terraform workspace:
   ```bash
   terraform init
   ```

2. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize the configuration.

3. Apply the configuration:
   ```bash
   terraform apply
   ```

## Post-Deployment

After successful deployment, you will receive:
1. SSH key retrieval instructions
2. Management node connection details (SSH and web interface)
3. Transcoding and proxy node details per region
4. Network and subnet information
5. Image and disk information

Use these details to:
1. Run the initial installer on the management node
2. Access the management interface to complete Pexip configuration
3. Provision transcoding and proxy nodes

For detailed Pexip configuration steps, refer to the [Pexip documentation](https://docs.pexip.com/admin/admin_intro.htm).

### Clean Up

To remove all resources:
```bash
terraform destroy
```

**Note:** This will delete all deployed resources.
