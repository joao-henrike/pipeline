# =============================================================================
# AZURE PROVIDERS.TF
# Requer: az login (ou Service Principal via variáveis de ambiente)
#   export ARM_SUBSCRIPTION_ID="..."
#   export ARM_TENANT_ID="..."
#   export ARM_CLIENT_ID="..."      # se usar Service Principal
#   export ARM_CLIENT_SECRET="..."  # se usar Service Principal
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    # Permite destruir Resource Group mesmo com recursos dentro
    resource_group { prevent_deletion_if_contains_resources = false }
    # Evita purga automática de Key Vaults ao destruir
    key_vault { purge_soft_delete_on_destroy = false }
  }
  subscription_id = var.subscription_id
}
