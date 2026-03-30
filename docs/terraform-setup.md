# Terraform Setup Guide

## Prerequisites
1. Install Terraform >= 1.0
2. Configure AWS CLI with credentials
3. Create SSH key pair in AWS

## Setup Steps

### 1. Initialize Terraform
```bash
cd infrastructure/terraform
terraform init
```

### 2. Plan Deployment
```bash
terraform plan -var="key_name=your-key-name"
```

### 3. Apply Configuration
```bash
terraform apply -var="key_name=your-key-name" -auto-approve
```

### 4. Verify Deployment
```bash
# Get public IP
terraform output public_ip

# Test SSH connection
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output public_ip)
```

### 5. Cleanup (if needed)
```bash
terraform destroy -auto-approve
```

## Troubleshooting

### Common Issues
- **SSH Key Not Found**: Ensure key pair exists in AWS region
- **Permission Denied**: Check SSH key permissions (chmod 400)
- **Instance Not Accessible**: Verify security group allows SSH

### Next Steps
Once VM is accessible, proceed with:
1. Honeypot installation
2. Logging configuration
3. Multi-region setup
