# =============================================================================
# Basic Pexip Infinity Deployment Example
# =============================================================================

This example demonstrates the minimum required configuration for deploying Pexip Infinity on Google Cloud Platform (GCP). It creates a single management node and one transcoding node in a single region.

# =============================================================================
# Architecture Overview
# =============================================================================

This deployment creates:
- 1 Management Node (N2 High CPU 4 machine type)
- 1 Transcoding Node (N2 High CPU 4 machine type)
- Required firewall rules for management and media traffic
- Uses existing Pexip images (no image upload required)

# =============================================================================
# Prerequisites
# =============================================================================

1. A GCP project with billing enabled
2. Required APIs (automatically enabled by the module):
   - Compute Engine API
   - Cloud Resource Manager API
   - IAM API

3. Existing Pexip Infinity images in your project:
   - Management Node image
   - Conferencing Node image

4. Existing Network Infrastructure:
   - VPC network
   - Subnet in your chosen region

# =============================================================================
# Required Configuration
# =============================================================================

The following variables must be configured in your `terraform.tfvars`:

1. **Project Configuration**
   ```hcl
   project_id = "your-project-id"
   ```

2. **Network Configuration**
   ```hcl
   regions = [{
     region      = "us-central1"
     network     = "existing-vpc-name"
     subnet_name = "existing-subnet-name"
   }]
   ```

3. **Image Configuration**
   ```hcl
   pexip_images = {
     management = {
       image_name = "pexip-infinity-management-v30"
     }
     conferencing = {
       image_name = "pexip-infinity-conferencing-v30"
     }
   }
   ```

4. **Management Access**
   ```hcl
   management_access = {
     cidr_ranges = ["YOUR_IP_RANGE"]  # Restrict in production!
   }
   ```

# =============================================================================
# Default Configurations
# =============================================================================

The module provides sensible defaults for:

1. **Firewall Rules**
   - Management services (SSH, Admin UI, Provisioning)
   - Call services (SIP, H.323, Teams, Google Meet)
   - Optional services disabled by default (Teams Hub, Syslog, SMTP, LDAP)

2. **Machine Types**
   - Management Node: N2 High CPU 4
   - Transcoding Node: N2 High CPU 4

# =============================================================================
# Usage
# =============================================================================

1. Copy and configure:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. Deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. After deployment:
   - Download SSH key from Secret Manager
   - Access Management Node via HTTPS
   - Complete initial setup wizard
   - Configure transcoding nodes

# =============================================================================
# Clean Up
# =============================================================================

To remove all resources:
```bash
terraform destroy
```

**Note:** This will delete all resources including any stored data.
