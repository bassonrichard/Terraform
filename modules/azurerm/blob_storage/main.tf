locals {
  name = "${var.name_prefix}${var.name}sa"
}

resource "azurerm_storage_account" "storage_account" {
  name                = local.name
  resource_group_name = var.resource_group_name

  location                 = var.location
  access_tier              = "Hot"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # azurerm 5.x defaults this to false; public containers need it on.
  allow_nested_items_to_be_public = anytrue([for c in var.storage_containers : c.container_access_type != "private"])

  dynamic "custom_domain" {
    for_each = var.custom_domain_name != null ? [var.custom_domain_name] : []
    content {
      name          = custom_domain.value
      use_subdomain = var.custom_domain_use_subdomain
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "storage_container" {

  for_each = { for idx, container in var.storage_containers : idx => container }

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = each.value.container_access_type
}