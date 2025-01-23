# Basic Pexip Infinity Deployment Example

This example demonstrates the minimum configuration required to deploy Pexip Infinity in GCP. It includes:
- Single region deployment (us-central1)
- Using existing Pexip images
- Management node
- Two transcoding nodes
- Default configurations for services

## Prerequisites

1. A GCP project with required APIs enabled
2. An existing VPC network and subnet in us-central1
3. Existing Pexip Infinity images in your project:
   - Management Node image
   - Conferencing Node image

## Usage

1. Create a `terraform.tfvars` file with your specific values:

```hcl
project_id = "your-project-id"
network_name = "your-vpc-network"
subnet_name = "your-subnet-name"

management_image_name = "pexip-infinity-management-v30"
conferencing_image_name = "pexip-infinity-conferencing-v30"
```

2. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

## Node Configuration

### Management Node
- Region: us-central1
- Machine Type: n2-highcpu-4 (default)
- Public IP: Yes (default)

### Transcoding Nodes
- Count: 2 nodes
- Region: us-central1
- Machine Type: n2-highcpu-8 (default)
- Public IP: Yes (default)

## Default Services
All core services are enabled by default:
- SSH access
- Conference node provisioning
- SIP
- H.323
- Microsoft Teams
- Google Meet

## Notes
- This is a basic configuration suitable for testing or small deployments
- Uses default values for optional parameters
- All management interfaces are accessible from any IP (0.0.0.0/0)
- Consider adding proxy nodes and restricting management access for production use
