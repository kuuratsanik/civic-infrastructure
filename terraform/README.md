# Civic Infrastructure - Terraform Integration

Infrastructure-as-code for Windows 11 Pro civic infrastructure deployment.

## Directory Structure

```
terraform/
├── azure/                  # Azure Sentient Workspace deployment
│   ├── sentient-workspace.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── README.md
├── storage/                # MinIO evidence storage (future)
├── networking/             # Cloudflare Tunnel (future)
└── .gitignore
```

## Quick Start

### 1. Install Terraform

```powershell
winget install HashiCorp.Terraform
```

### 2. Deploy Azure Resources

```powershell
cd terraform/azure
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

See `azure/README.md` for detailed instructions.

## Features

- **Declarative Infrastructure**: Define desired state, Terraform handles execution
- **Version Controlled**: All infrastructure configurations in Git
- **Idempotent**: Safe to run multiple times
- **Governance Integration**: Logs to blockchain ledger, creates evidence bundles
- **Environment Separation**: Dev, staging, prod configurations

## Integration with civic-infrastructure

Terraform complements existing PowerShell workflows:

- **Terraform**: Infrastructure provisioning (Azure resources, storage, networking)
- **PowerShell**: Configuration management (Windows registry, services, apps)
- **Blockchain**: Audit trail for both layers
- **Evidence Bundles**: Capture Terraform state + PowerShell output

## Coming Soon

- **MinIO Storage**: Self-hosted S3-compatible evidence storage
- **Cloudflare Tunnel**: Secure remote access without port forwarding
- **Custom Provider**: Native Windows customization via Terraform

## Documentation

- [Azure Deployment Guide](azure/README.md)
- [Terraform Integration Strategy](../TERRAFORM-INTEGRATION-STRATEGY.md)
- [civic-infrastructure Docs](../docs/)

