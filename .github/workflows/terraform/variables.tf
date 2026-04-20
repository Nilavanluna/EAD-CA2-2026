variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = "ca2-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "North Europe"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "ca2-aks"
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique)"
  type        = string
  default     = "ca2acr2026"
}

variable "backup_storage_name" {
  description = "Storage account for MongoDB backups (must be globally unique)"
  type        = string
  default     = "ca2mongobackup2026"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    project     = "EAD-CA2"
    environment = "production"
    managed_by  = "terraform"
  }
}
