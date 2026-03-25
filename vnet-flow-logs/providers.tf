terraform {
  backend "azurerm" {
    resource_group_name  = "<YOUR_TERRAFORM_STATE_RG>"
    storage_account_name = "<YOUR_TERRAFORM_STATE_SA>"
    container_name       = "tfstate"
    key                  = "vnet-flow-logs-retro.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
