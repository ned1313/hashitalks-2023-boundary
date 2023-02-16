provider "azurerm" {
  features {}
}

resource "random_id" "id" {
  byte_length = 4
}

locals {
  resource_group_name = "${var.naming_prefix}-boundary-${random_id.id.hex}"
  vault_name          = "${var.naming_prefix}-boundary-${random_id.id.hex}"
  worker_user_id      = "${var.naming_prefix}-boundary-${random_id.id.hex}"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "~> 2.0"
  resource_group_name = azurerm_resource_group.main.name
  vnet_name           = azurerm_resource_group.main.name
  address_space       = var.address_space
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names

  # Service endpoints used for Key Vault to the workers
  subnet_service_endpoints = {
    (var.subnet_names[0]) = ["Microsoft.KeyVault"]
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}

data "http" "my_ip" {
  url = "https://ipinfo.io/ip"
}

data "azurerm_client_config" "current" {}

# Create key vault and access policies
resource "azurerm_key_vault" "main" {
  name                       = local.vault_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment     = false
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name                  = "standard"
  enable_rbac_authorization = true

  # Only allow access to the Key Vault from your public IP address and the worker subnets 
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = ["${data.http.my_ip.response_body}/32"]
    virtual_network_subnet_ids = [module.vnet.vnet_subnets[0]]

  }

}

# Access policy for worker VMs
# Uses the Worker user assigned identity
resource "azurerm_role_assignment" "worker" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Access policy allowing your credentials full access to Key Vault
resource "azurerm_role_assignment" "you" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Populate Key Vault with secrets for Boundary
resource "azurerm_key_vault_secret" "boundary_username" {
  name         = "boundary-cluster-username"
  value        = var.boundary_worker_user.username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.you
  ]
}

resource "azurerm_key_vault_secret" "boundary_password" {
  name         = "boundary-cluster-password"
  value        = var.boundary_worker_user.password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.you
  ]
}

resource "azurerm_key_vault_secret" "boundary_id" {
  name         = "boundary-cluster-id"
  value        = var.boundary_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.you
  ]
}

resource "azurerm_key_vault_secret" "boundary_auth_method_id" {
  name         = "boundary-cluster-auth-method-id"
  value        = var.boundary_password_auth_method_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.you
  ]
}