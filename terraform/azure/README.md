# Terraform Azure Sentient Workspace

Declarative infrastructure-as-code for Wave 9 Sentient Workspace deployment.

## Features

- **Azure OpenAI**: GPT-4 Turbo, GPT-4o, Text Embedding deployments
- **Storage**: Evidence bundles, blockchain backups, ISO builds, deployment logs
- **Optional**: Azure Functions (AI agents), Key Vault (secrets management)
- **Governance**: Blockchain ledger logging, evidence bundle generation
- **Configuration**: Auto-generated .env file for local development

## Prerequisites

1. **Terraform**: v1.13.0+ installed
2. **Azure CLI**: Logged in (`az login`)
3. **Azure Subscription**: Active subscription with permissions to create resources
4. **PowerShell**: 7+ for blockchain logging integration

## Quick Start

### 1. Configure Variables

Copy the example configuration and customize:

```powershell
cd terraform/azure
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

### 2. Initialize Terraform

Download required providers:

```powershell
terraform init
```

### 3. Plan Deployment

Preview what will be created (dry run):

```powershell
terraform plan
```

Review the plan carefully. You should see:

- 1 Resource Group
- 1 Cognitive Account (Azure OpenAI)
- 3 Cognitive Deployments (GPT-4 Turbo, GPT-4o, Text Embedding)
- 1 Storage Account
- 4 Storage Containers
- Optional: Functions, Key Vault

### 4. Deploy Infrastructure

Apply the Terraform configuration:

```powershell
terraform apply
```

Type `yes` when prompted to confirm.

Deployment takes ~5-10 minutes.

### 5. Verify Deployment

Check generated configuration file:

```powershell
Get-Content ../../config/.env
```

Verify blockchain ledger entry:

```powershell
Get-Content ../../logs/council_ledger.jsonl | ConvertFrom-Json | Select-Object -Last 1 | Format-List
```

Test Azure OpenAI endpoint:

```powershell
# Get endpoint from Terraform outputs
$endpoint = terraform output -raw openai_endpoint
$key = terraform output -raw openai_api_key

Write-Host "Endpoint: $endpoint"
Write-Host "API Key: $key"
```

## Terraform Commands

### View Outputs

```powershell
# Show all outputs
terraform output

# Show specific output (plain text)
terraform output openai_endpoint

# Show sensitive output
terraform output openai_api_key
```

### Update Infrastructure

Modify `terraform.tfvars` or `.tf` files, then:

```powershell
terraform plan   # Preview changes
terraform apply  # Apply changes
```

### Destroy Infrastructure

**Warning:** This deletes all resources!

```powershell
terraform destroy
```

Type `yes` to confirm permanent deletion.

## Configuration Variables

### Essential Variables

| Variable         | Description            | Default                  | Example         |
| ---------------- | ---------------------- | ------------------------ | --------------- |
| `environment`    | Deployment environment | `"dev"`                  | `"prod"`        |
| `azure_location` | Azure region           | `"westeurope"`           | `"northeurope"` |
| `deployed_by`    | Deployment actor       | `"civic-infrastructure"` | `"john.doe"`    |

### Azure OpenAI Variables

| Variable             | Description          | Default | Notes          |
| -------------------- | -------------------- | ------- | -------------- |
| `openai_sku`         | OpenAI SKU           | `"S0"`  | Standard tier  |
| `gpt4_capacity`      | GPT-4 Turbo capacity | `10`    | 10K tokens/min |
| `gpt4o_capacity`     | GPT-4o capacity      | `10`    | 10K tokens/min |
| `embedding_capacity` | Embedding capacity   | `10`    | 10K tokens/min |

### Storage Variables

| Variable                   | Description      | Default | Options              |
| -------------------------- | ---------------- | ------- | -------------------- |
| `storage_replication_type` | Replication type | `"LRS"` | LRS, GRS, RAGRS, ZRS |

### Optional Features

| Variable           | Description            | Default | Notes                       |
| ------------------ | ---------------------- | ------- | --------------------------- |
| `enable_functions` | Enable Azure Functions | `false` | For serverless agents       |
| `enable_key_vault` | Enable Key Vault       | `false` | For secrets management      |
| `functions_sku`    | Functions plan SKU     | `"Y1"`  | Y1=Consumption, EP1=Premium |

## Directory Structure

```
terraform/azure/
├── sentient-workspace.tf    # Main infrastructure definition
├── variables.tf             # Variable declarations
├── outputs.tf               # Output definitions
├── terraform.tfvars.example # Example configuration
└── README.md                # This file
```

## Outputs

After successful deployment, Terraform provides:

- `openai_endpoint` - Azure OpenAI API endpoint
- `openai_api_key` - API key (sensitive, use `terraform output openai_api_key`)
- `storage_account_name` - Storage account name
- `evidence_container_name` - Evidence bundles container
- `deployment_summary` - Full deployment summary

Outputs are also written to `config/.env` for PowerShell scripts.

## Integration with PowerShell Scripts

The Terraform deployment integrates with existing PowerShell workflows:

### Blockchain Ledger

Automatically logs deployment to `logs/council_ledger.jsonl`:

```json
{
  "action": "Terraform Azure Deployment",
  "actor": "Terraform",
  "metadata": {
    "ResourceGroup": "sentient-workspace-dev-rg",
    "OpenAIEndpoint": "https://...",
    "DeploymentMethod": "Terraform IaC"
  }
}
```

### Environment Configuration

Generates `config/.env` with all credentials:

```bash
AZURE_OPENAI_ENDPOINT=https://...
AZURE_OPENAI_API_KEY=...
AZURE_STORAGE_CONNECTION_STRING=...
```

PowerShell scripts can load this file:

```powershell
Get-Content config/.env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.+)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}
```

## Governance Integration

### Evidence Bundles

Create evidence bundle after deployment:

```powershell
$evidencePath = "evidence/terraform-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -Path $evidencePath -ItemType Directory -Force

# Capture Terraform state
terraform show -json | Out-File "$evidencePath/terraform-state.json"

# Capture outputs
terraform output -json | Out-File "$evidencePath/terraform-outputs.json"

# Create manifest
@{
    Timestamp = Get-Date -Format 'o'
    DeploymentMethod = 'Terraform'
    Actor = $env:USERNAME
    ResourceGroup = terraform output -raw resource_group_name
} | ConvertTo-Json | Out-File "$evidencePath/manifest.json"
```

### Timelock Mechanism

For production deployments, implement timelock:

```powershell
# Create proposal
$proposal = @{
    Action = 'Terraform Apply'
    ProposedBy = $env:USERNAME
    Timestamp = Get-Date -Format 'o'
    TimelockHours = 24
    Config = Get-Content terraform.tfvars
}

$proposal | ConvertTo-Json | Out-File "proposals/terraform-apply-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# After 24 hours, execute
terraform apply -auto-approve
```

## State Management

### Local State (Default)

Terraform stores state in `terraform.tfstate` (local file).

**Pros:**

- Simple, no setup required
- Works immediately

**Cons:**

- Not suitable for team collaboration
- No automatic backups
- Risk of state file corruption

### Remote State (Recommended for Production)

Store state in Azure Storage:

1. Create state storage:

```powershell
az group create --name civic-infrastructure-state-rg --location westeurope
az storage account create --name civicterraformstate --resource-group civic-infrastructure-state-rg --sku Standard_LRS
az storage container create --name tfstate --account-name civicterraformstate
```

2. Uncomment backend configuration in `sentient-workspace.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "civic-infrastructure-state-rg"
  storage_account_name = "civicterraformstate"
  container_name       = "tfstate"
  key                  = "sentient-workspace.tfstate"
}
```

3. Initialize backend:

```powershell
terraform init -migrate-state
```

**Pros:**

- Team collaboration (shared state)
- State locking (prevents conflicts)
- Automatic backups
- Version history

## Troubleshooting

### Authentication Issues

```powershell
# Verify Azure CLI login
az account show

# Re-login if needed
az login

# Set correct subscription
az account set --subscription "<subscription-id>"
```

### Provider Registration

If you see "provider not registered" errors:

```powershell
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Web
```

### Quota Limits

Azure OpenAI has regional capacity limits. If deployment fails:

1. Try different region (`azure_location` variable)
2. Request quota increase in Azure Portal
3. Reduce capacity (`gpt4_capacity` variable)

### State Lock Issues

If state is locked:

```powershell
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

## Cost Estimation

Estimated monthly costs (dev environment):

| Resource                   | SKU            | Estimated Cost  |
| -------------------------- | -------------- | --------------- |
| Azure OpenAI               | S0             | ~$0 + usage     |
| Storage Account            | LRS            | ~$1-5           |
| Azure Functions (optional) | Y1 Consumption | ~$0 + usage     |
| Key Vault (optional)       | Standard       | ~$0.03 + usage  |
| **Total (base)**           |                | **~$1-5/month** |

Usage costs:

- GPT-4 Turbo: ~$0.01/1K tokens
- GPT-4o: ~$0.005/1K tokens
- Text Embedding: ~$0.0001/1K tokens
- Storage transactions: ~$0.01/10K operations

**Production estimates will be higher due to GRS storage, Premium Functions, etc.**

## Next Steps

1. **Test Deployment**: Verify all resources work
2. **Integrate with Scripts**: Update PowerShell scripts to use Terraform outputs
3. **Setup MinIO**: Deploy MinIO for evidence storage (next section)
4. **Configure Cloudflare**: Setup Cloudflare Tunnel for remote access
5. **Enable Remote State**: Migrate to Azure Storage backend for production

## Additional Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure OpenAI Service Docs](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [civic-infrastructure Documentation](../../docs/)

