# Advanced Pexip Infinity Deployment Example

This example demonstrates a full-featured deployment of Pexip Infinity on Google Cloud Platform (GCP). It includes multi-region support, configurable management access, and automated node deployment.

## Architecture Overview

This deployment creates:
- Management Node in the primary region
- Transcoding Nodes across multiple regions
- Proxy Nodes for edge connectivity
- Secure firewall rules for management and media traffic
- GCS bucket for Pexip image storage

## Prerequisites

1. A GCP project with billing enabled
2. The following APIs enabled:
   - Compute Engine API
   - Cloud Resource Manager API
   - IAM API
   - Secret Manager API
   - Storage API

3. Pexip Infinity images:
   - Management Node image (.tar.gz)
   - Conferencing Node image (.tar.gz)

4. Network Infrastructure:
   - VPC network
   - Subnets in each deployment region
   - External IP addresses (if using public IPs)

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Update `terraform.tfvars` with your configuration:
   - Set your GCP project ID
   - Configure network settings
   - Set management access CIDR ranges
   - Update Pexip image paths
   - Configure node specifications

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the deployment plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Security Features

### Management Access
- SSH (port 22)
- Admin UI (port 443)
- Provisioning (port 8443)
- Access restricted to specified CIDR ranges

### Media Services
- SIP/SIP-TLS (ports 5060/5061)
- H.323 (ports 1720/1719)
- Microsoft Teams integration
- Google Meet integration
- Open to 0.0.0.0/0 by default

### Internal Communication
- Secure IPsec between nodes
- Automated firewall rule configuration

## Node Types

### Management Node
- System configuration and licensing
- Conference scheduling
- One per deployment

### Transcoding Nodes
- Media processing
- Conference hosting
- Scalable across regions

### Proxy Nodes
- Call signaling
- Media forwarding
- Edge connectivity

## Outputs

After successful deployment, you'll receive:
- Management node access details
- Node IP addresses
- Network configuration summary
- Connection instructions

## Clean Up

To destroy the deployment:
```bash
terraform destroy
```

**Note:** This will remove all resources including stored data. Ensure you have backups if needed.
