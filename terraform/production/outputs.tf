output "sql_server_id" {
  description = "Resource ID of the Entra-only Azure SQL logical server."
  value       = azurerm_mssql_server.sql.id
}

output "sql_server_fqdn" {
  description = "Private SQL server DNS name; verify private resolution from approved client networks."
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "elastic_pool_ids" {
  description = "Resource IDs of the deployed elastic pools."
  value       = { for name, pool in azurerm_mssql_elasticpool.pool : name => pool.id }
}

output "database_ids" {
  description = "Resource IDs of the deployed pooled databases."
  value       = { for name, database in azurerm_mssql_database.database : name => database.id }
}

output "private_endpoint_id" {
  description = "Resource ID of the SQL Private Endpoint."
  value       = azurerm_private_endpoint.sql.id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the diagnostic destination workspace."
  value       = azurerm_log_analytics_workspace.sql.id
}
