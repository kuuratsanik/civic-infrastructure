# Variables for Sentient Workspace Azure Deployment
# Customize these values for your environment

# Environment Configuration
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "deployed_by" {
  description = "Username or identifier of who deployed this infrastructure"
  type        = string
  default     = "civic-infrastructure"
}

# Azure Configuration
variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

# Azure OpenAI Configuration
variable "openai_sku" {
  description = "Azure OpenAI SKU (S0 = Standard)"
  type        = string
  default     = "S0"
}

variable "gpt4_model_version" {
  description = "GPT-4 Turbo model version"
  type        = string
  default     = "turbo-2024-04-09"
}

variable "gpt4_capacity" {
  description = "GPT-4 Turbo capacity (tokens per minute in thousands)"
  type        = number
  default     = 10
}

variable "gpt4o_model_version" {
  description = "GPT-4o model version"
  type        = string
  default     = "2024-05-13"
}

variable "gpt4o_capacity" {
  description = "GPT-4o capacity (tokens per minute in thousands)"
  type        = number
  default     = 10
}

variable "embedding_capacity" {
  description = "Text embedding model capacity"
  type        = number
  default     = 10
}

variable "openai_network_acls_default_action" {
  description = "Default network ACL action (Allow or Deny)"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.openai_network_acls_default_action)
    error_message = "Network ACLs default action must be Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for OpenAI access (optional)"
  type        = list(string)
  default     = []
}

# Storage Configuration
variable "storage_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Invalid storage replication type."
  }
}

# Azure Functions Configuration
variable "enable_functions" {
  description = "Enable Azure Functions for AI agents"
  type        = bool
  default     = false
}

variable "functions_sku" {
  description = "Azure Functions SKU (Y1 = Consumption, EP1 = Elastic Premium, P1V2 = Premium V2)"
  type        = string
  default     = "Y1"
}

# Key Vault Configuration
variable "enable_key_vault" {
  description = "Enable Azure Key Vault for secrets management"
  type        = bool
  default     = false
}
