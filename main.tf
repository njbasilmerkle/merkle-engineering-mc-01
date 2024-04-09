terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.98.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "uma_rg" {
  name = "uma-rg-engineering-dev"
}

resource "azurerm_storage_account" "uma_sa" {
  name                     = "umasanbtestdeploy001"
  resource_group_name      = data.azurerm_resource_group.uma_rg.name
  location                 = data.azurerm_resource_group.uma_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "uma_kv" {
  name                = "umakvnbtestdeploy001"
  location            = data.azurerm_resource_group.uma_rg.location
  resource_group_name = data.azurerm_resource_group.uma_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Delete"
    ]

    storage_permissions = [
      "Get",
      "List",
      "Set",
      "SetSAS",
      "GetSAS",
      "DeleteSAS",
      "Update",
      "RegenerateKey"
    ]
  }
}

resource "azurerm_key_vault_managed_storage_account" "uma_msa" {
  name                         = "umamsanbtestdeploy001"
  key_vault_id                 = azurerm_key_vault.uma_kv.id
  storage_account_id           = azurerm_storage_account.uma_sa.id
  storage_account_key          = "key1"
  regenerate_key_automatically = true
  regeneration_period          = "P1M"
}