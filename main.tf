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
  is_hns_enabled           = true

  tags = {
    CostCode       = "UK045"
    CreatorContact = "noel.basil@merkle.com"
    OwnerContact   = "noel.basil@merkle.com"
    Org            = "Merkle Analytics"
    Description    = "Storage account for engineering dev environment"
  }
}

resource "azurerm_key_vault" "uma_kv" {
  name                = "uma-kv-nbtestdeploy-001"
  location            = data.azurerm_resource_group.uma_rg.location
  resource_group_name = data.azurerm_resource_group.uma_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  purge_protection_enabled = false

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

  tags = {
    CostCode       = "UK045"
    CreatorContact = "noel.basil@merkle.com"
    OwnerContact   = "noel.basil@merkle.com"
    Org            = "Merkle Analytics"
    Description    = "Key vault for storing secrets in engineering dev environment"
  }
}

resource "azurerm_data_factory" "uma_df" {
  name                = "uma-df-nbtestdeploy-001"
  location            = data.azurerm_resource_group.uma_rg.location
  resource_group_name = data.azurerm_resource_group.uma_rg.name

  tags = {
    CostCode       = "UK045"
    CreatorContact = "noel.basil@merkle.com"
    OwnerContact   = "noel.basil@merkle.com"
    Org            = "Merkle Analytics"
    Description    = "Data factory for storing secrets in engineering dev environment"
  }
}

data "azurerm_virtual_network" "uma_vnet" {
  name                = "uma-vnet-subscription-001"
  resource_group_name = data.azurerm_resource_group.uma_rg.name
}

resource "azurerm_network_security_group" "uma_pub_nsg" {
  name                = "uma-pub-nsg"
  location            = data.azurerm_virtual_network.uma_vnet.location
  resource_group_name = data.azurerm_resource_group.uma_rg.name
}

resource "azurerm_network_security_group" "uma_priv_nsg" {
  name                = "uma-priv-nsg"
  location            = data.azurerm_virtual_network.uma_vnet.location
  resource_group_name = data.azurerm_resource_group.uma_rg.name
}

resource "azurerm_subnet" "uma_pub_sn" {
  name                 = "uma-sn-nbtestdeploy_pub-001"
  resource_group_name  = data.azurerm_resource_group.uma_rg.name
  virtual_network_name = data.azurerm_virtual_network.uma_vnet.name
  address_prefixes     = ["10.1.2.0/24"]

  delegation {
    name = "databricks"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "uma_priv_sn" {
  name                 = "uma-sn-nbtestdeploy_priv-001"
  resource_group_name  = data.azurerm_resource_group.uma_rg.name
  virtual_network_name = data.azurerm_virtual_network.uma_vnet.name
  address_prefixes     = ["10.1.3.0/24"]

  delegation {
    name = "databricks"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "uma_pub_nsg_association" {
  subnet_id                 = azurerm_subnet.uma_pub_sn.id
  network_security_group_id = azurerm_network_security_group.uma_pub_nsg.id
  depends_on                = [azurerm_network_security_group.uma_pub_nsg, azurerm_subnet.uma_pub_sn]
}

resource "azurerm_subnet_network_security_group_association" "uma_priv_nsg_association" {
  subnet_id                 = azurerm_subnet.uma_priv_sn.id
  network_security_group_id = azurerm_network_security_group.uma_priv_nsg.id
  depends_on                = [azurerm_network_security_group.uma_priv_nsg, azurerm_subnet.uma_priv_sn]
}

resource "azurerm_databricks_workspace" "uma_dbw" {
  name                        = "uma-dbw-nbtestdeploy-001"
  resource_group_name         = data.azurerm_resource_group.uma_rg.name
  location                    = data.azurerm_virtual_network.uma_vnet.location
  sku                         = "standard"
  managed_resource_group_name = "${data.azurerm_resource_group.uma_rg.name}-databricks"

  custom_parameters {
    virtual_network_id = data.azurerm_virtual_network.uma_vnet.id
    public_subnet_name = azurerm_subnet.uma_pub_sn.name
    private_subnet_name = azurerm_subnet.uma_priv_sn.name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.uma_pub_nsg_association.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.uma_priv_nsg_association.id
  }

  tags = {
    CostCode       = "UK045"
    CreatorContact = "noel.basil@merkle.com"
    OwnerContact   = "noel.basil@merkle.com"
    Org            = "Merkle Analytics"
    Description    = "Databricks workspace with custom VNet"
  }
}
