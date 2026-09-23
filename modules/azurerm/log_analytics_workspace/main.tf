resource "azurerm_log_analytics_workspace" "az_log_analytics_workspace" {

  resource_group_name                = var.resource_group_name
  location                           = var.location
  name                               = var.name
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_access_type     = var.internet_ingestion_enabled ? "Enabled" : "Disabled"
  internet_query_access_type         = var.internet_query_enabled ? "Enabled" : "Disabled"
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day
  sku                                = var.sku

  tags = var.tags
}
