terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Remote state stored in Azure Blob — ensures idempotent, team-safe runs
  backend "azurerm" {
    resource_group_name  = "ca2-tfstate-rg"
    storage_account_name = "ca2tfstate"
    container_name       = "tfstate"
    key                  = "ead-ca2.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── Resource Group ──────────────────────────────────────────────────────────
resource "azurerm_resource_group" "ca2" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ── AKS Cluster ─────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "ca2" {
  name                = var.cluster_name
  location            = azurerm_resource_group.ca2.location
  resource_group_name = azurerm_resource_group.ca2.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = "1.29"

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Rolling update strategy at cluster level
  auto_scaler_profile {
    balance_similar_node_groups = true
    skip_nodes_with_system_pods = true
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  # Enable Azure Monitor / Container Insights
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.ca2.id
  }

  tags = var.tags
}

# ── Log Analytics (monitoring) ───────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "ca2" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.ca2.location
  resource_group_name = azurerm_resource_group.ca2.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ── Azure Container Registry (optional — project uses GHCR but ACR shown for completeness) ──
resource "azurerm_container_registry" "ca2" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.ca2.name
  location            = azurerm_resource_group.ca2.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

# Grant AKS kubelet identity pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.ca2.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.ca2.kubelet_identity[0].object_id
}

# ── Storage account for MongoDB backups ─────────────────────────────────────
resource "azurerm_storage_account" "backups" {
  name                     = var.backup_storage_name
  resource_group_name      = azurerm_resource_group.ca2.name
  location                 = azurerm_resource_group.ca2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "mongo_backups" {
  name                  = "mongo-backups"
  storage_account_name  = azurerm_storage_account.backups.name
  container_access_type = "private"
}
