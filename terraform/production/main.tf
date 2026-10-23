locals {
  common_tags = merge(var.tags, {
    managedBy = "terraform"
    service   = "azure-sql"
  })
}

data "azurerm_client_config" "current" {}

resource "azurerm_mssql_server" "sql" {
  name                          = var.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = local.common_tags

  azuread_administrator {
    login_username              = var.sql_entra_admin_login
    object_id                   = var.sql_entra_admin_object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_server_extended_auditing_policy" "sql" {
  server_id              = azurerm_mssql_server.sql.id
  log_monitoring_enabled = true
}

resource "azurerm_mssql_elasticpool" "pool" {
  for_each = var.pools

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_mssql_server.sql.name
  max_size_gb         = each.value.max_size_gb
  zone_redundant      = each.value.zone_redundant
  license_type        = each.value.license_type
  tags                = local.common_tags

  sku {
    name     = each.value.sku_name
    tier     = each.value.tier
    family   = each.value.family
    capacity = each.value.capacity
  }

  per_database_settings {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }
}

resource "azurerm_mssql_database" "database" {
  for_each = var.databases

  name                                = each.key
  server_id                           = azurerm_mssql_server.sql.id
  elastic_pool_id                     = azurerm_mssql_elasticpool.pool[each.value.pool_name].id
  sku_name                            = "ElasticPool"
  max_size_gb                         = each.value.max_size_gb
  storage_account_type                = each.value.backup_storage_type
  transparent_data_encryption_enabled = true
  tags                                = local.common_tags

  short_term_retention_policy {
    retention_days = each.value.short_term_retention_days
  }

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = each.value.max_size_gb <= var.pools[each.value.pool_name].max_size_gb
      error_message = "Database max_size_gb cannot exceed its assigned pool's max_size_gb."
    }
  }
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pep-${var.sql_server_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-${var.sql_server_name}"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_log_analytics_workspace" "sql" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.workspace_retention_in_days
  tags                = local.common_tags
}

resource "azurerm_monitor_action_group" "sql_oncall" {
  name                = "ag-${var.sql_server_name}-oncall"
  resource_group_name = var.resource_group_name
  short_name          = "SQLOnCall"
  tags                = local.common_tags

  email_receiver {
    name                    = "sql-on-call"
    email_address           = var.operator_email
    use_common_alert_schema = true
  }
}

data "azurerm_monitor_diagnostic_categories" "server" {
  resource_id = azurerm_mssql_server.sql.id
}

data "azurerm_monitor_diagnostic_categories" "master_database" {
  resource_id = "${azurerm_mssql_server.sql.id}/databases/master"
}

resource "azurerm_monitor_diagnostic_setting" "server" {
  name                           = "diag-${var.sql_server_name}"
  target_resource_id             = azurerm_mssql_server.sql.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.sql.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.server.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "master_database" {
  name                           = "diag-${var.sql_server_name}-master"
  target_resource_id             = "${azurerm_mssql_server.sql.id}/databases/master"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.sql.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.master_database.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

data "azurerm_monitor_diagnostic_categories" "pool" {
  for_each    = azurerm_mssql_elasticpool.pool
  resource_id = each.value.id
}

resource "azurerm_monitor_diagnostic_setting" "pool" {
  for_each                       = azurerm_mssql_elasticpool.pool
  name                           = "diag-${each.key}"
  target_resource_id             = each.value.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.sql.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.pool[each.key].log_category_types)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

data "azurerm_monitor_diagnostic_categories" "database" {
  for_each    = azurerm_mssql_database.database
  resource_id = each.value.id
}

resource "azurerm_monitor_diagnostic_setting" "database" {
  for_each                       = azurerm_mssql_database.database
  name                           = "diag-${each.key}"
  target_resource_id             = each.value.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.sql.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.database[each.key].log_category_types)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_metric_alert" "pool_cpu" {
  for_each = azurerm_mssql_elasticpool.pool

  name                     = "alert-${each.key}-cpu"
  resource_group_name      = var.resource_group_name
  scopes                   = [each.value.id]
  target_resource_type     = "Microsoft.Sql/servers/elasticPools"
  target_resource_location = var.location
  description              = "Average elastic pool CPU exceeded the approved threshold."
  severity                 = 2
  frequency                = "PT1M"
  window_size              = "PT5M"
  enabled                  = true
  tags                     = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Sql/servers/elasticPools"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.pool_cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.sql_oncall.id
  }
}

resource "azurerm_monitor_metric_alert" "pool_data_io" {
  for_each = azurerm_mssql_elasticpool.pool

  name                     = "alert-${each.key}-data-io"
  resource_group_name      = var.resource_group_name
  scopes                   = [each.value.id]
  target_resource_type     = "Microsoft.Sql/servers/elasticPools"
  target_resource_location = var.location
  description              = "Average elastic pool data I/O exceeded the approved threshold."
  severity                 = 2
  frequency                = "PT1M"
  window_size              = "PT5M"
  enabled                  = true
  tags                     = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Sql/servers/elasticPools"
    metric_name      = "data_io_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.pool_data_io_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.sql_oncall.id
  }
}
