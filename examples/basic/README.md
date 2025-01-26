Basic Pexip Infinity Deployment Example
=====================================

This example demonstrates the minimum required configuration for deploying Pexip Infinity on Google Cloud Platform (GCP). It creates a single management node and one transcoding node in a single region.

## Quick Start

All required files are included in this directory. To use this example:

1. Copy all files from this directory to your workspace
2. Rename `terraform.tfvars.example` to `terraform.tfvars`
3. Update the values in `terraform.tfvars` with your configuration
4. Run `terraform init`, `terraform plan`, and `terraform apply`

## Overview

This example creates the essential infrastructure needed to run Pexip Infinity on Google Cloud:
- Single management node and transcoding node
- Basic network configuration using an existing VPC and subnet
- Required firewall rules for Pexip services
- Image configuration using existing GCP images

### Features

- Single-region deployment
- Basic deployment with minimum required configuration
- Static IP support for all nodes
- Essential firewall rules for core services

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
   - Existing VPC Network and subnet in your target region
4. Pexip Infinity images:
   - Pexip Infinity images already in your GCP project (specify source_image)
   - Pexip Infinity GCP .tar.gz files can be found here on Pexip's website:
     - https://www.pexip.com/help-center/platform-download
   - Documentation on how to convert:
     - https://docs.pexip.com/admin/gcp_disk_images.htm

### Required Variables Configuration

1. Project:
   ```hcl
   # GCP project ID where Pexip Infinity will be deployed
   project_id = "your-project-id"
   ```

2. Network Configuration:
   ```hcl
   # Network Configuration - Must have an existing VPC network and subnet
   regions = [{
     region      = "us-central1"     # Primary region for deployment
     network     = "pexip-infinity"  # Name of existing VPC network
     subnet_name = "pexip-subnet"    # Name of existing subnet in the VPC
   }]
   ```

3. Image Configuration:
   ```hcl
   # Using existing images from your GCP project
   pexip_images = {
     upload_files = false  # Set to false when using existing GCP images
     management = {
       image_name = "pexip-infinity-management-v36"  # Name of existing management node image
     }
     conferencing = {
       image_name = "pexip-infinity-conferencing-v36"  # Name of existing conferencing node image
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
   # Management Node Configuration
   management_node = {
     name      = "mgmt-1"             # Name for the management node
     region    = "us-central1"        # Must match one of the regions above
     public_ip = true                 # Set false for internal-only access
     machine_type = "n2-highcpu-4"    # Pexip recommended
   }
   ```

6. Transcoding Node Configuration:
   ```hcl
   # Transcoding Node Configuration
   transcoding_nodes = {
     regional_config = {
       "us-central1" = {                  # Region definition- must match one of the regions above
         count        = 1                 # Number of nodes to deploy
         name         = "transcode"       # Name prefix for instances
         public_ip    = true              # Set false for internal-only access
         machine_type = "n2-highcpu-4"    # Machine type based on capacity
       }
     }
   }
   ```

### Optional Variables Configuration

1. Services Configuration (Optional):
   ```hcl
   # Service configuration toggles for firewall rules
   services = {
     # Management services default to enabled
     enable_ssh               = true    # SSH access (port 22)
     enable_conf_provisioning = true    # Conferencing Node Provisioning (port 8443)

     # Call services default to enabled
     enable_sip   = true    # SIP signaling and media
     enable_h323  = true    # H.323 signaling and media
     enable_teams = true    # Microsoft Teams media
     enable_gmeet = true    # Google Meet media

     # Optional services default to disabled
     enable_teams_hub = false    # Microsoft Teams hub
     enable_syslog    = false    # Syslog
     enable_smtp      = false    # SMTP
     enable_ldap      = false    # LDAP
   }
   ```

## Post-Deployment

After successful deployment, you will receive:
1. SSH key retrieval instructions
2. Management node connection details (SSH and web interface)
3. Transcoding node details
4. Network and subnet information
5. Image and disk information

Use these details to:
1. Run the initial installer on the management node
2. Access the management interface to complete Pexip configuration
3. Provision transcoding node

For detailed Pexip configuration steps, refer to the [Pexip documentation](https://docs.pexip.com/admin/admin_intro.htm).

### Clean Up

To remove all resources:
```bash
terraform destroy
```

**Note:** This will delete all deployed resources.
