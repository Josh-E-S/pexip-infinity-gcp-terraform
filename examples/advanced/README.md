# Advanced Pexip Infinity Deployment Example

This example demonstrates a full-featured deployment of Pexip Infinity across multiple regions. It includes:
- Multi-region deployment (4 regions)
- Custom machine types and disk sizes
- All optional services enabled
- Image upload functionality
- 2 transcoding nodes and 1 proxy node per region

## Prerequisites

1. A GCP project with required APIs enabled
2. An existing VPC network with subnets in each region:
   - us-central1
   - us-east1
   - europe-west1
   - asia-southeast1
3. Pexip Infinity image files downloaded locally:
   - Management Node image
   - Conferencing Node image

## Usage

1. Create a `terraform.tfvars` file with your specific values:

```hcl
project_id = "your-project-id"
network_name = "your-vpc-network"

subnet_names = {
  "us-central1"      = "subnet-central"
  "us-east1"         = "subnet-east"
  "europe-west1"     = "subnet-europe"
  "asia-southeast1"  = "subnet-asia"
}

management_cidrs = [
  "10.0.0.0/8",      # Internal network
  "203.0.113.0/24"   # VPN network
]

management_image_path = "/path/to/Pexip_Infinity_Management_Node_v30.tar.gz"
conferencing_image_path = "/path/to/Pexip_Infinity_Conferencing_Node_v30.tar.gz"
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
- Machine Type: n2-highcpu-8 (upgraded for higher capacity)
- Disk Size: 150GB (larger for more logs)
- Public IP: Yes

### Transcoding Nodes (per region)
- Count: 2 nodes per region
- Machine Type: n2-highcpu-16
- Disk Size: 80GB
- Public IP: Yes

### Proxy Nodes (per region)
- Count: 1 node per region
- Machine Type: n2-highcpu-4
- Disk Size: 50GB
- Public IP: Yes

## Services Enabled
- Core Services:
  - SIP
  - H.323
  - Microsoft Teams
  - Google Meet
- Optional Services:
  - Teams Hub
  - Syslog
  - SMTP
  - LDAP

## Notes
- This is an advanced configuration suitable for large-scale deployments
- Adjust machine types and node counts based on your capacity requirements
- Review and restrict management_cidrs for production use
- Consider your high availability requirements when choosing regions
