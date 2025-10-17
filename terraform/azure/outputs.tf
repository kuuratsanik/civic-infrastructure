# Outputs for Sentient Workspace Azure Deployment
# These values are used by PowerShell scripts and displayed after deployment

# Resource Group
output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.sentient.name
}

output "resource_group_id" {
  description = "ID of the Azure resource group"
  value       = azurerm_resource_group.sentient.id
}

# Azure OpenAI
output "openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_api_key" {
  description = "Azure OpenAI API key (sensitive)"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "openai_deployment_gpt4_turbo" {
  description = "GPT-4 Turbo deployment name"
  value       = azurerm_cognitive_deployment.gpt4_turbo.name
}

output "openai_deployment_gpt4o" {
  description = "GPT-4o deployment name"
  value       = azurerm_cognitive_deployment.gpt4o.name
}

output "openai_deployment_embedding" {
  description = "Text embedding deployment name"
  value       = azurerm_cognitive_deployment.text_embedding.name
}

# Storage Account
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.sentient.name
}

output "storage_account_primary_key" {
  description = "Primary access key for storage account (sensitive)"
  value       = azurerm_storage_account.sentient.primary_access_key
  sensitive   = true
}

output "storage_connection_string" {
  description = "Storage account connection string (sensitive)"
  value       = azurerm_storage_account.sentient.primary_connection_string
  sensitive   = true
}

output "evidence_container_name" {
  description = "Name of the evidence bundles container"
  value       = azurerm_storage_container.evidence_bundles.name
}

output "blockchain_backup_container_name" {
  description = "Name of the blockchain backups container"
  value       = azurerm_storage_container.blockchain_backups.name
}

output "iso_builds_container_name" {
  description = "Name of the ISO builds container"
  value       = azurerm_storage_container.iso_builds.name
}

# Azure Functions (conditional)
output "function_app_name" {
  description = "Name of the Azure Functions app"
  value       = var.enable_functions ? azurerm_windows_function_app.sentient_agents[0].name : null
}

output "function_app_default_hostname" {
  description = "Default hostname of the Azure Functions app"
  value       = var.enable_functions ? azurerm_windows_function_app.sentient_agents[0].default_hostname : null
}

# Key Vault (conditional)
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.sentient[0].name : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.sentient[0].vault_uri : null
}

# Environment Configuration
output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "location" {
  description = "Azure region"
  value       = var.azure_location
}

# Configuration File
output "env_file_path" {
  description = "Path to generated .env configuration file"
  value       = local_file.env_file.filename
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    resource_group    = azurerm_resource_group.sentient.name
    openai_endpoint   = azurerm_cognitive_account.openai.endpoint
    gpt4_turbo        = azurerm_cognitive_deployment.gpt4_turbo.name
    gpt4o             = azurerm_cognitive_deployment.gpt4o.name
    embedding         = azurerm_cognitive_deployment.text_embedding.name
    storage_account   = azurerm_storage_account.sentient.name
    evidence_container = azurerm_storage_container.evidence_bundles.name
    functions_enabled = var.enable_functions
    key_vault_enabled = var.enable_key_vault
    environment       = var.environment
  }
}
