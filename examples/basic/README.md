# Basic Pexip Infinity Deployment

This example demonstrates a basic Pexip Infinity deployment with:
- Single region (us-west1)
- Existing VPC network and subnet
- Pre-existing Pexip images
- One management node
- One transcoding node
- All default service configurations

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the project ID in `terraform.tfvars`
3. Ensure the specified network, subnet, and images exist in your project
4. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Notes
- This example uses module defaults for most settings
- Management access is allowed from anywhere (0.0.0.0/0)
- Common services (SIP, H.323, Teams, Meet) are enabled
- Optional services are disabled
