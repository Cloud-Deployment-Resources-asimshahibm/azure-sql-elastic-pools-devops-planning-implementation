terraform {
  required_version = ">= 1.8.5, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.81.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  resource_provider_registrations = "none"

  features {}
}
