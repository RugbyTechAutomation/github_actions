terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "3.105.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
    http = {
      source = "hashicorp/http"
    }
    time = {
      source = "hashicorp/time"
    }
    azapi = {
      source = "azure/azapi"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
  storage_use_azuread = true
  subscription_id     = "19067dda-d761-44a6-b79d-29a8e342f633" # azdev
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
