variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group the blob storage resides in."
}

variable "name_prefix" {
  type        = string
  description = "(Required) The prefix to use for all resources."
}

variable "name" {
  type        = string
  description = "(Required) The name of the blob storage."
}

variable "location" {
  type        = string
  description = "(Required) Specifies the location of the blob storage."
}

variable "storage_containers" {
  type = list(object({
    name                  = string
    container_access_type = string
  }))
}

variable "custom_domain_name" {
  type        = string
  description = "(Optional) The custom domain name for the storage account."
  default     = null
}

variable "custom_domain_use_subdomain" {
  type        = bool
  description = "(Optional) Verify the custom domain through an asverify subdomain CNAME instead of a direct CNAME."
  default     = true
}

variable "blob_delete_retention_days" {
  type        = number
  description = "(Optional) Days a deleted blob stays recoverable (soft delete). Leave null to keep soft delete off."
  default     = null

  validation {
    condition     = var.blob_delete_retention_days == null ? true : var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "blob_delete_retention_days must be between 1 and 365."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of the resource"
  type        = map(any)
  default     = {}
}