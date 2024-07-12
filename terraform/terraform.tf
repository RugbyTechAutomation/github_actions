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
    # use_oidc         = true # Can also be set via `ARM_USE_OIDC` environment variable.
    # use_azuread_auth = true
  }
  # # cloud {
  # backend "remote" {
  #   organization = "davidjyeo"
  #   # token        = ""

  #   workspaces {
  #     # project = "Azure"
  #     name = "State"
  #   }
  # }

  # backend "azurerm" {
  #   storage_account_name = "sttfrmmgmtuks01"           #var.TFSTATE_STORAGE_ACCOUNT
  #   container_name       = "tfstate"                   #var.TFSTATE_CONTAINER
  #   key                  = "ansible.terraform.tfstate" #var.TFSTATE_KEY
  #   # subscription_id      = var.SUBSCRIPTION_ID
  #   # tenant_id            = var.TENANT_ID
  #   resource_group_name = "rg-tfrm-mgmt-uks-01" #var.TFSTATE_RESOURCE_GROUP
  #   # use_azuread_auth     = true
  # }

}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
  storage_use_azuread = true
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

provider "azuread" {
  # use_oidc  = true                                        # or use the environment variable "ARM_USE_OIDC=true"
  tenant_id = data.azurerm_subscription.current.tenant_id #88ef261e-b19b-4d71-9afd-cdac31a6dcda
  # features {}
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
