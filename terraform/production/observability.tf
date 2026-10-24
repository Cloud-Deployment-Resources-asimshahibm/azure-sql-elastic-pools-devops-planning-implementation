locals {
  pool_metric_definitions = {
    cpu_percent = {
      metric_name = "cpu_percent"
      description = "Elastic pool CPU utilization"
    }
    physical_data_read_percent = {
      metric_name = "physical_data_read_percent"
      description = "Elastic pool physical data read utilization"
    }
    log_write_percent = {
      metric_name = "log_write_percent"
      description = "Elastic pool transaction log write utilization"
    }
    workers_percent = {
      metric_name = "workers_percent"
      description = "Elastic pool worker utilization"
    }
    sessions_percent = {
      metric_name = "sessions_percent"
      description = "Elastic pool session utilization"
    }
    storage_percent = {
      metric_name = "storage_percent"
      description = "Elastic pool data storage utilization"
    }
  }

  pool_metric_alerts = {
    for alert in flatten([
      for pool_name, pool in azurerm_mssql_elasticpool.pool : [
        for key, metric in local.pool_metric_definitions : {
          key         = "${pool_name}-${key}"
          pool_id     = pool.id
          metric_name = metric.metric_name
          description = metric.description
          threshold   = var.pool_metric_alert_thresholds[key]
        }
      ]
    ]) : alert.key => alert
  }

  elastic_pool_metrics_query = <<-KQL
    AzureMetrics
    | where TimeGenerated > ago(24h)
    | where ResourceProvider =~ "MICROSOFT.SQL"
    | where ResourceId contains "/elasticPools/"
    | where MetricName in ("CPU percentage", "Data IO percentage", "Log IO percentage", "Workers percentage", "Sessions percentage", "Data space used percent")
    | summarize AverageValue = avg(Average), PeakValue = max(Maximum) by bin(TimeGenerated, 5m), Resource, MetricName
    | render timechart
  KQL

  elastic_pool_current_metrics_query = <<-KQL
    AzureMetrics
    | where TimeGenerated > ago(30m)
    | where ResourceProvider =~ "MICROSOFT.SQL"
    | where ResourceId contains "/elasticPools/"
    | where MetricName in ("CPU percentage", "Data IO percentage", "Log IO percentage", "Workers percentage", "Sessions percentage", "Data space used percent")
    | summarize arg_max(TimeGenerated, Average, Maximum) by ResourceId, MetricName
    | project TimeGenerated, ResourceId, MetricName, Average, Maximum
    | order by ResourceId asc, MetricName asc
  KQL

  workbook_data = {
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json  = "Elastic-pool platform metrics for the selected time range. Thresholds are configured per pool metric in Terraform; tune them from workload evidence. Metric visibility and log ingestion are subject to Azure Monitor and workspace configuration."
          style = "info"
        }
        name = "Operations guidance"
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query   = local.elastic_pool_metrics_query
          size    = 0
          timeContext = {
            durationMs = 86400000
          }
          queryType               = 0
          resourceType            = "microsoft.operationalinsights/workspaces"
          crossComponentResources = [azurerm_log_analytics_workspace.sql.id]
          visualization           = "timechart"
          title                   = "Elastic pool saturation trends (24 hours)"
          showAnalytics           = true
        }
        name = "Elastic pool saturation trends"
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query   = local.elastic_pool_current_metrics_query
          size    = 0
          timeContext = {
            durationMs = 1800000
          }
          queryType               = 0
          resourceType            = "microsoft.operationalinsights/workspaces"
          crossComponentResources = [azurerm_log_analytics_workspace.sql.id]
          visualization           = "table"
          title                   = "Latest pool metric samples"
          showAnalytics           = true
        }
        name = "Latest pool metric samples"
      }
    ]
    fallbackResourceIds = [azurerm_log_analytics_workspace.sql.id]
    "$schema"           = "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
  }
}

resource "azurerm_monitor_metric_alert" "pool_saturation" {
  for_each = local.pool_metric_alerts

  name                     = "alert-${each.key}"
  resource_group_name      = var.resource_group_name
  scopes                   = [each.value.pool_id]
  target_resource_type     = "Microsoft.Sql/servers/elasticPools"
  target_resource_location = var.location
  description              = "${each.value.description} exceeded its approved threshold."
  severity                 = 2
  frequency                = "PT1M"
  window_size              = "PT5M"
  enabled                  = true
  tags                     = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Sql/servers/elasticPools"
    metric_name      = each.value.metric_name
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.sql_oncall.id
  }
}

resource "azurerm_application_insights_workbook" "sql_operations" {
  name                = uuidv5("url", "${data.azurerm_client_config.current.subscription_id}/${var.resource_group_name}/${var.sql_server_name}/sql-operations-workbook")
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "Azure SQL Elastic Pool Operations"
  category            = "workbook"
  source_id           = lower(azurerm_log_analytics_workspace.sql.id)
  description         = "Elastic-pool utilization, saturation trends, and latest metric samples."
  data_json           = jsonencode(local.workbook_data)
  tags                = local.common_tags
}
