Advanced Pexip Infinity Deployment Example
=====================================

This example demonstrates a multi-region, full-featured deployment of Pexip Infinity on Google Cloud Platform (GCP). It creates a management node, multiple transcoding nodes across regions, and proxy nodes for optimal global coverage.

### Architecture Overview

This deployment creates:
- 1 Management Node with enhanced specifications
- Multiple Transcoding Nodes across regions
- Proxy Nodes for call signaling
- Required firewall rules for all Pexip services
- Uses existing Pexip images (no image upload required)

### Prerequisites

1. A GCP project with billing enabled
2. Required APIs (automatically enabled by the module):
   - Compute Engine API
   - Cloud Resource Manager API
   - IAM API
   - Secret Manager API

3. Existing Network Infrastructure:
   - VPC network spanning multiple regions
   - Subnets in each target region

4. Pexip Infinity images:
   - Option 1: Images already in your GCP project (specify source_image)
   - Option 2: Local .tar.gz files to upload (specify source_file)

### Required Configuration

Copy `terraform.tfvars.example` to `terraform.tfvars` and configure:

1. **Project and Network**
   ```hcl
   project_id = "your-project-id"

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

2. **Image Configuration**
   ```hcl
   pexip_images = {
     upload_files = false
     management = {
       image_name = "pexip-infinity-management-v36"
     }
     conferencing = {
       image_name = "pexip-infinity-conferencing-v36"
     }
   }
   ```

3. **Node Configuration**
   ```hcl
   management_node = {
     name         = "mgmt-primary"
     region       = "us-central1"
     public_ip    = true
     machine_type = "n2-highcpu-8"    # Enhanced for larger deployments
     disk_size    = 150               # Larger disk for logs
   }

   transcoding_nodes = {
     regional_config = {
       "us-central1" = {
         count        = 1
         name         = "transcode-central-1"
         public_ip    = true
         machine_type = "n2-highcpu-8"
         disk_size    = 50
       },
       "us-east1" = {
         count        = 1
         name         = "transcode-east-1"
         public_ip    = true
         machine_type = "n2-highcpu-8"
         disk_size    = 50
       }
     }
   }

   proxy_nodes = {
     regional_config = {
       "us-central1" = {
         count        = 1
         name         = "proxy-central"
         public_ip    = true
         machine_type = "n2-highcpu-4"
         disk_size    = 50
       }
     }
   }
   ```

### Default Values

The module provides defaults for:

1. **Management Access Example**
   ```hcl
   management_access = {
     cidr_ranges = [
       "10.0.0.0/8",        # Internal corporate network
       "192.168.0.0/16",    # VPN network
       "203.0.113.0/24"     # Office public network
     ]
   }
   ```

2. **Services**
   ```hcl
   services = {
     enable_ssh               = true
     enable_conf_provisioning = true
     enable_sip              = true
     enable_h323            = true
     enable_teams           = true
     enable_gmeet           = true
     enable_teams_hub        = true
     enable_syslog           = true
     enable_smtp             = true
     enable_ldap             = true
   }
   ```

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
3. Transcoding and proxy node details per region
4. Network and subnet information
5. Image and disk information

Use these details to:
1. Run the initial installer on the management node
2. Access the management interface to complete Pexip configuration
3. Provision transcoding and proxy nodes
   - Configure your Pexip Infinity deployment following the [Pexip documentation](https://docs.pexip.com/admin/admin_intro.htm)

### Clean Up

To remove all resources:
```bash
terraform destroy
```

**Note:** This will delete all resources.
