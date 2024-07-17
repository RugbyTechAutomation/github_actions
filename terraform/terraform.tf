terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
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
    azuread = {
      source = "hashicorp/azuread"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stgtfstatedjy01"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
    # client_id            = "034c052e-a6e5-4252-9b10-df537302b2b8"
    # tenant_id            = "88ef261e-b19b-4d71-9afd-cdac31a6dcda"
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
  use_oidc            = true
  storage_use_azuread = true
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

provider "azuread" {
  use_oidc  = true                                        # or use the environment variable "ARM_USE_OIDC=true"
  tenant_id = data.azurerm_subscription.current.tenant_id #88ef261e-b19b-4d71-9afd-cdac31a6dcda
  # features {}
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
