output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.ca2.name
}

output "aks_resource_group" {
  description = "Resource group containing the AKS cluster"
  value       = azurerm_resource_group.ca2.name
}

output "kube_config" {
  description = "Raw kubeconfig (sensitive)"
  value       = azurerm_kubernetes_cluster.ca2.kube_config_raw
  sensitive   = true
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.ca2.login_server
}

output "backup_storage_account" {
  description = "Storage account for MongoDB backups"
  value       = azurerm_storage_account.backups.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.ca2.id
}
