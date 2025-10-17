# Sentient Workspace - Azure OpenAI Infrastructure
# Declarative infrastructure-as-code for Wave 9 deployment
# Replaces Deploy-Sentient-Simple.ps1 Azure sections

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend configuration for state management
  # Uncomment after initial deployment to enable remote state
  # backend "azurerm" {
  #   resource_group_name  = "civic-infrastructure-state-rg"
  #   storage_account_name = "civicterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "sentient-workspace.tfstate"
  # }
}

provider "azurerm" {
  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  skip_provider_registration = true
}

# Local variables for configuration
locals {
  project_name = "sentient-workspace"
  environment  = var.environment
  location     = var.azure_location

  common_tags = {
    Project     = "civic-infrastructure"
    Component   = "sentient-workspace"
    Environment = var.environment
    ManagedBy   = "Terraform"
    DeployedBy  = var.deployed_by
    Timestamp   = timestamp()
  }
}

# Resource Group for Sentient Workspace
resource "azurerm_resource_group" "sentient" {
  name     = "${local.project_name}-${local.environment}-rg"
  location = local.location
  tags     = local.common_tags
}

# Azure OpenAI Cognitive Services Account
resource "azurerm_cognitive_account" "openai" {
  name                  = "${local.project_name}-openai-${local.environment}"
  resource_group_name   = azurerm_resource_group.sentient.name
  location              = azurerm_resource_group.sentient.location
  kind                  = "OpenAI"
  sku_name              = var.openai_sku
  custom_subdomain_name = "${local.project_name}-openai-${local.environment}"

  tags = merge(local.common_tags, {
    Service = "Azure OpenAI"
  })

  # Network rules (default: allow all, can be restricted)
  network_acls {
    default_action = var.openai_network_acls_default_action

    # Optional: Add IP rules for restricted access
    # ip_rules = var.allowed_ip_ranges
  }

  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# GPT-4 Turbo Deployment
resource "azurerm_cognitive_deployment" "gpt4_turbo" {
  name                 = "gpt-4-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = var.gpt4_model_version
  }

  scale {
    type = "Standard"
  }

  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# GPT-4o (Omni) Deployment - Latest multimodal model
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = var.gpt4o_model_version
  }

  scale {
    type = "Standard"
  }

  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# Text Embedding Model Deployment
resource "azurerm_cognitive_deployment" "text_embedding" {
  name                 = "text-embedding-3-large"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-large"
    version = "1"
  }

  scale {
    type = "Standard"
  }

  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}# Storage Account for evidence bundles, logs, and workspace data
resource "azurerm_storage_account" "sentient" {
  name                     = replace("${local.project_name}${local.environment}sa", "-", "")
  resource_group_name      = azurerm_resource_group.sentient.name
  location                 = azurerm_resource_group.sentient.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(local.common_tags, {
    Service = "Storage"
  })
}

# Container for evidence bundles
resource "azurerm_storage_container" "evidence_bundles" {
  name                  = "evidence-bundles"
  storage_account_name  = azurerm_storage_account.sentient.name
  container_access_type = "private"
}

# Container for blockchain ledger backups
resource "azurerm_storage_container" "blockchain_backups" {
  name                  = "blockchain-backups"
  storage_account_name  = azurerm_storage_account.sentient.name
  container_access_type = "private"
}

# Container for ISO builds
resource "azurerm_storage_container" "iso_builds" {
  name                  = "iso-builds"
  storage_account_name  = azurerm_storage_account.sentient.name
  container_access_type = "private"
}

# Container for deployment logs
resource "azurerm_storage_container" "deployment_logs" {
  name                  = "deployment-logs"
  storage_account_name  = azurerm_storage_account.sentient.name
  container_access_type = "private"
}

# Azure Functions (optional, for serverless AI agents)
resource "azurerm_service_plan" "sentient_functions" {
  count               = var.enable_functions ? 1 : 0
  name                = "${local.project_name}-functions-plan-${local.environment}"
  resource_group_name = azurerm_resource_group.sentient.name
  location            = azurerm_resource_group.sentient.location
  os_type             = "Windows"
  sku_name            = var.functions_sku

  tags = merge(local.common_tags, {
    Service = "Azure Functions"
  })
}

resource "azurerm_windows_function_app" "sentient_agents" {
  count               = var.enable_functions ? 1 : 0
  name                = "${local.project_name}-agents-${local.environment}"
  resource_group_name = azurerm_resource_group.sentient.name
  location            = azurerm_resource_group.sentient.location

  storage_account_name       = azurerm_storage_account.sentient.name
  storage_account_access_key = azurerm_storage_account.sentient.primary_access_key
  service_plan_id            = azurerm_service_plan.sentient_functions[0].id

  site_config {
    application_stack {
      node_version = "~18"
    }
  }

  app_settings = {
    "OPENAI_ENDPOINT"          = azurerm_cognitive_account.openai.endpoint
    "OPENAI_API_KEY"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key[0].id})"
    "BLOCKCHAIN_LEDGER_PATH"   = "C:/ai-council/logs/council_ledger.jsonl"
    "EVIDENCE_CONTAINER"       = azurerm_storage_container.evidence_bundles.name
    "STORAGE_CONNECTION_STRING" = azurerm_storage_account.sentient.primary_connection_string
  }

  tags = merge(local.common_tags, {
    Service = "AI Agents"
  })
}

# Key Vault for secrets management (optional but recommended)
resource "azurerm_key_vault" "sentient" {
  count               = var.enable_key_vault ? 1 : 0
  name                = "${local.project_name}-kv-${local.environment}"
  resource_group_name = azurerm_resource_group.sentient.name
  location            = azurerm_resource_group.sentient.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = merge(local.common_tags, {
    Service = "Key Vault"
  })
}

# Key Vault access policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  count        = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.sentient[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

# Store OpenAI API key in Key Vault
resource "azurerm_key_vault_secret" "openai_key" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "openai-api-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = azurerm_key_vault.sentient[0].id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Generate .env file for local development
resource "local_file" "env_file" {
  filename = "${path.module}/../../config/.env"

  content = <<-EOT
    # Sentient Workspace Environment Configuration
    # Generated by Terraform on ${timestamp()}
    # DO NOT COMMIT THIS FILE TO GIT

    # Azure OpenAI Configuration
    AZURE_OPENAI_ENDPOINT=${azurerm_cognitive_account.openai.endpoint}
    AZURE_OPENAI_API_KEY=${azurerm_cognitive_account.openai.primary_access_key}
    AZURE_OPENAI_DEPLOYMENT_GPT4=${azurerm_cognitive_deployment.gpt4_turbo.name}
    AZURE_OPENAI_DEPLOYMENT_GPT4O=${azurerm_cognitive_deployment.gpt4o.name}
    AZURE_OPENAI_DEPLOYMENT_EMBEDDING=${azurerm_cognitive_deployment.text_embedding.name}

    # Azure Storage Configuration
    AZURE_STORAGE_ACCOUNT_NAME=${azurerm_storage_account.sentient.name}
    AZURE_STORAGE_ACCOUNT_KEY=${azurerm_storage_account.sentient.primary_access_key}
    AZURE_STORAGE_CONNECTION_STRING=${azurerm_storage_account.sentient.primary_connection_string}
    EVIDENCE_CONTAINER=${azurerm_storage_container.evidence_bundles.name}
    BLOCKCHAIN_BACKUP_CONTAINER=${azurerm_storage_container.blockchain_backups.name}

    # Resource Configuration
    AZURE_SUBSCRIPTION_ID=${data.azurerm_client_config.current.subscription_id}
    AZURE_RESOURCE_GROUP=${azurerm_resource_group.sentient.name}
    AZURE_LOCATION=${azurerm_resource_group.sentient.location}

    # Environment
    ENVIRONMENT=${local.environment}
    DEPLOYED_BY=${var.deployed_by}
    DEPLOYED_AT=${timestamp()}
  EOT

  file_permission = "0600"
}

# Log deployment to blockchain ledger
resource "null_resource" "blockchain_logging" {
  triggers = {
    deployment_id = azurerm_cognitive_account.openai.id
    timestamp     = timestamp()
  }

  provisioner "local-exec" {
    command     = <<-EOT
      powershell -ExecutionPolicy Bypass -Command "
        . '${path.module}/../../scripts/utilities/Add-CouncilLedgerEntry.ps1'
        Add-CouncilLedgerEntry `
          -Action 'Terraform Azure Deployment' `
          -Actor 'Terraform' `
          -Metadata @{
            ResourceGroup = '${azurerm_resource_group.sentient.name}'
            OpenAIEndpoint = '${azurerm_cognitive_account.openai.endpoint}'
            DeploymentMethod = 'Terraform IaC'
            Environment = '${local.environment}'
            GPT4Deployment = '${azurerm_cognitive_deployment.gpt4_turbo.name}'
            GPT4oDeployment = '${azurerm_cognitive_deployment.gpt4o.name}'
            StorageAccount = '${azurerm_storage_account.sentient.name}'
          }
      "
    EOT
    interpreter = ["powershell", "-Command"]
    working_dir = path.module
  }

  depends_on = [
    azurerm_cognitive_deployment.gpt4_turbo,
    azurerm_cognitive_deployment.gpt4o,
    azurerm_storage_account.sentient,
    local_file.env_file
  ]
}
