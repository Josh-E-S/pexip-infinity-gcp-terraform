Basic Pexip Infinity Deployment Example
=====================================

This example demonstrates the minimum required configuration for deploying Pexip Infinity on Google Cloud Platform (GCP). It creates a single management node and one transcoding node in a single region.

### Architecture Overview

This deployment creates:
- 1 Management Node
- 1 Transcoding Node
- Required firewall rules for management and media traffic
- Uses existing Pexip images (no image upload required)

### Prerequisites

1. A GCP project with billing enabled
2. Required APIs (automatically enabled by the module):
   - Compute Engine API
   - Cloud Resource Manager API
   - IAM API
   - Secret Manager API

3. Existing Network Infrastructure:
   - VPC network
   - Subnet in your target region

4. Pexip Infinity images:
   - Option 1: Images already in your GCP project (specify source_image)
   - Option 2: Local .tar.gz files to upload (specify source_file)

### Required Configuration

Copy `terraform.tfvars.example` to `terraform.tfvars` and configure:

1. **Project and Network**
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

2. **Image Configuration**
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

3. **Node Configuration**
   ```hcl
   # Management Node Configuration
   management_node = {
     name      = "mgmt-1"        # Name prefix for the instance
     region    = "us-central1"   # Must match one of the regions above
     public_ip = true            # Set false for internal-only access
   }

   # Transcoding Node Configuration
   transcoding_nodes = {
     regional_config = {
       "us-central1" = {
         count        = 1                 # Number of nodes to deploy
         name         = "transcode"       # Name prefix for instances
         public_ip    = true             # Set false for internal-only access
         machine_type = "n2-highcpu-4"   # Machine type based on capacity
       }
     }
   }
   ```

### Default Values

The module providesdefaults for:

1. **Management Access**
   ```hcl
   management_access = {
     cidr_ranges = ["0.0.0.0/0"]  # Restrict this in production!
   }
   ```

2. **Machine Types** (if not specified)
   - Management Node: n2-highcpu-4
   - Transcoding Node: n2-highcpu-4

### Usage

1. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Post-Deployment

After successful deployment, the module will output:
1. SSH key retrieval instructions
2. Management node connection details (SSH and web interface)
3. Transcoding node details
4. Network and subnet information
5. Image and disk information

Use these details to:
1. Run the initial installer on the management node
2. Access the management interface to complete Pexip configuration
3. Provision transcoding node
   - Configure your Pexip Infinity deployment following the [Pexip documentation](https://docs.pexip.com/admin/admin_intro.htm)

### Clean Up

To remove all resources:
```bash
terraform destroy
```

**Note:** This will delete all resources.
