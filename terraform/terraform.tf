terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    managed_disk {
      expand_without_downtime = true
    }
    virtual_machine {
      skip_shutdown_and_force_delete = true
    }
  }
  # subscription_id = "d0f6eb41-3e86-48da-bc57-893eab20796f"
  # subscription_id = "19067dda-d761-44a6-b79d-29a8e342f633" # AzDev
}

provider "azapi" {}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}
