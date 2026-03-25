terraform {
  backend "azurerm" {
    resource_group_name  = "<YOUR_TERRAFORM_STATE_RG>"
    storage_account_name = "<YOUR_TERRAFORM_STATE_SA>"
    container_name       = "tfstate"
    key                  = "vnet-flowlogs.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}
