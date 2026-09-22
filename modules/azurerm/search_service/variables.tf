variable "name" {
  type        = string
  description = "(Required) The name of the search service."

}

variable "name_prefix" {
  type        = string
  description = "(Required) The prefix to use for all resources."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the search service"
}

variable "sku" {
  type        = string
  description = "The SKU of the search service"

  default = "free"

  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.sku)
    error_message = "The SKU must be either 'free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'"
  }
}

variable "semantic_search_sku" {
  type        = string
  description = "(Optional) The semantic ranker tier: 'free' or 'standard'. Null leaves semantic ranking off."
  default     = null

  validation {
    condition     = var.semantic_search_sku == null ? true : contains(["free", "standard"], var.semantic_search_sku)
    error_message = "The semantic search SKU must be either 'free' or 'standard'."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of the resource"
  type        = map(any)
  default     = {}
}