resource "azurerm_search_service" "search_service" {
  name                = "${var.name_prefix}-${var.name}-search"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  semantic_search_sku = var.semantic_search_sku

  authentication_failure_mode = "http403"

  tags = var.tags
}