# Cloud-Native Honeynet Platform

A distributed, adaptive honeynet platform with centralized control, dynamic deception, and cloud-native deployment.

## Quick Start

### Prerequisites
- Terraform >= 1.0
- AWS CLI configured with credentials
- SSH key pair

### Initial Setup
```bash
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

### Verification
```bash
# Get the public IP
terraform output public_ip

# SSH into the VM
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output public_ip)
```

## Architecture
This is the foundational setup for a distributed honeynet system. Current implementation provisions a single VM as the building block for future multi-region deployments.

## Next Steps
- Honeypot installation and configuration
- Multi-region deployment
- Logging and monitoring setup
- Automation and orchestration 
