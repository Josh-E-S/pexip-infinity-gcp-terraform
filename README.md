# README.md
# Terraform Pexip Infinity

Infrastructure as Code templates for deploying Pexip Infinity video conferencing platform on multiple cloud providers.

## Overview

This repository contains Terraform templates for deploying and managing Pexip Infinity video conferencing infrastructure. The templates are designed to be modular and support multiple cloud providers, starting with Google Cloud Platform (GCP).

### Features

- Single management node deployment
- Multi-region conference node support
- Customizable instance configurations
- Production-ready security settings
- Variable-driven architecture

## Cloud Provider Support

- GCP (Current)
- AWS (Planned)
- Azure (Planned)

## Prerequisites

- Terraform >= 1.0.0
- GCP Account and Project
- Service Account with necessary permissions
- Pexip Infinity images accessible in your project

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/Josh-E-S/terraform-pexip-infinity.git
cd terraform-pexip-infinity/gcp
```

2. Copy and modify the example variables file:
```bash
cp examples/basic/terraform.tfvars.example terraform.tfvars
```

3. Initialize Terraform:
```bash
terraform init
```

4. Deploy the infrastructure:
```bash
terraform plan
terraform apply
```

## Usage

### Basic Deployment

For a basic deployment with a single management node and conference node, use the basic example:

```bash
cd examples/basic
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

### Production Deployment

For a production deployment with multiple conference nodes across regions, use the production example:

```bash
cd examples/production
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

## Configuration

### Required Variables

- `project_id` - Your GCP project ID
- `region` - Primary region for deployment
- `management_node_zone` - Zone for management node
- `pexip_password` - Initial admin password

### Optional Variables

- `conference_nodes` - Map of conference node configurations
- `network_tags` - Additional network tags
- `labels` - Resource labels