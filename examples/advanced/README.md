# Advanced Pexip Infinity Deployment

This example demonstrates an advanced Pexip Infinity deployment with:
- Multi-region deployment (us-west1 and us-east1)
- Separate VPC networks per region
- Custom image upload
- Restricted management access
- All services enabled (including optional ones)
- Multiple transcoding and proxy nodes

## Features
- **Multi-Region**: Deploys across us-west1 and us-east1 for high availability
- **Network Isolation**: Uses separate VPC networks for each region
- **Custom Images**: Uploads and uses custom Pexip images
- **Security**: Restricts management access to specific CIDR ranges
- **Services**: Enables all available services including Teams Hub, Syslog, SMTP, and LDAP
- **Scaling**: Deploys transcoding and proxy nodes in both regions

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the configuration in `terraform.tfvars`:
   - Set your project ID
   - Configure management access CIDR ranges
   - Set paths to your Pexip image files
3. Ensure the specified networks and subnets exist in your project
4. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Notes
- This example demonstrates most available features
- Consider your requirements before enabling all services
- Adjust machine types based on your performance needs
- Review the CIDR ranges for management access
