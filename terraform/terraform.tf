terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    # tls = {
    #   source  = "hashicorp/tls"
    # }
    local = {
      source = "hashicorp/local"
    }
    # random = {
    #   source = "hashicorp/random"
    # }
    # http = {
    #   source = "hashicorp/http"
    # }
    # time = {
    #   source = "hashicorp/time"
    # }
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
  subscription_id     = "19067dda-d761-44a6-b79d-29a8e342f633" # azdev
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
