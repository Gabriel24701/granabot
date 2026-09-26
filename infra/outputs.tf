output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "container_app_fqdn" {
  value = azurerm_container_app.api.latest_revision_fqdn
}

output "storage_queue_name" {
  value = azurerm_storage_queue.telegram_messages.name
}
