# variable "HCP_TOKEN" {}

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

  cloud {
    organization = "davidjyeo"
    token        = var.HCP_TOKEN

    workspaces {
      name = "State"
    }
  }

  # backend "azurerm" {
  #   storage_account_name = var.TFSTATE_STORAGE_ACCOUNT #"ukpptfrm01strgacc"
  #   container_name       = var.TFSTATE_CONTAINER       #"state"
  #   key                  = var.TFSTATE_KEY             #"cckcom.terraform.tfstate"
  #   use_azuread_auth     = true
  #   subscription_id      = var.SUBSCRIPTION_ID        #"ee805603-e7a3-4754-be96-c8201fec77c8"
  #   tenant_id            = var.TENANT_ID              #"8df4b91e-bf72-411d-9902-5ecc8f1e6c11"
  #   resource_group_name  = var.TFSTATE_RESOURCE_GROUP #"uk-pp-tfrm-01-rg"
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
