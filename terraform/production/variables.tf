variable "resource_group_name" {
  description = "Existing, dedicated application resource group."
  type        = string
}

variable "location" {
  description = "Approved Azure region for the SQL and monitoring resources."
  type        = string
}

variable "sql_server_name" {
  description = "Globally unique lowercase SQL logical server name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,63}$", var.sql_server_name))
    error_message = "Use a globally unique SQL server name containing only lowercase letters and digits (1-63 characters)."
  }
}

variable "sql_entra_admin_login" {
  description = "Display name of the approved Microsoft Entra administrator group."
  type        = string
}

variable "sql_entra_admin_object_id" {
  description = "Object ID of the approved Microsoft Entra administrator group."
  type        = string

  validation {
    condition = can(regex(
      "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
      var.sql_entra_admin_object_id
    )) && lower(var.sql_entra_admin_object_id) != "00000000-0000-0000-0000-000000000000"
    error_message = "sql_entra_admin_object_id must be the non-zero GUID of the approved Entra administrator group."
  }
}

variable "private_endpoint_subnet_id" {
  description = "Existing, network-approved subnet resource ID for the SQL Private Endpoint."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Existing privatelink.database.windows.net Private DNS zone resource ID."
  type        = string
}

variable "pools" {
  description = "Workload-aligned vCore pool definitions; size from measured workload data."
  type = map(object({
    sku_name       = string
    tier           = string
    family         = string
    license_type   = string
    capacity       = number
    max_size_gb    = number
    min_capacity   = number
    max_capacity   = number
    zone_redundant = bool
  }))

  validation {
    condition     = length(var.pools) > 0
    error_message = "Define at least one approved elastic pool."
  }

  validation {
    condition = alltrue([
      for pool in values(var.pools) :
      !pool.zone_redundant || pool.tier == "BusinessCritical"
    ])
    error_message = "Zone-redundant vCore pools require the BusinessCritical tier; also verify regional SKU support."
  }

  validation {
    condition = alltrue([
      for pool in values(var.pools) :
      pool.capacity > 0 &&
      pool.capacity == floor(pool.capacity) &&
      pool.max_size_gb > 0 &&
      pool.min_capacity >= 0 &&
      pool.min_capacity <= pool.max_capacity &&
      pool.max_capacity <= pool.capacity &&
      contains(["LicenseIncluded", "BasePrice"], pool.license_type)
    ])
    error_message = "Pools require positive integer capacity, valid storage and per-database limits, and an approved license_type."
  }
}

variable "databases" {
  description = "Pooled databases mapped to a defined pool."
  type = map(object({
    pool_name                 = string
    max_size_gb               = number
    short_term_retention_days = number
    backup_storage_type       = string
  }))

  validation {
    condition     = length(var.databases) > 0
    error_message = "Define at least one database or remove this module's database resources for a server-only deployment."
  }

  validation {
    condition = alltrue([
      for database in values(var.databases) :
      contains(keys(var.pools), database.pool_name)
    ])
    error_message = "Every database pool_name must match a key in pools."
  }

  validation {
    condition = alltrue([
      for database in values(var.databases) :
      database.short_term_retention_days >= 1 && database.short_term_retention_days <= 35
    ])
    error_message = "short_term_retention_days must be between 1 and 35 days."
  }

  validation {
    condition = alltrue([
      for database in values(var.databases) :
      database.max_size_gb > 0 &&
      contains(["Geo", "GeoZone", "Local", "Zone"], database.backup_storage_type)
    ])
    error_message = "Databases require positive max_size_gb and an approved backup_storage_type (Geo, GeoZone, Local, or Zone)."
  }
}

variable "workspace_name" {
  description = "Globally unique Log Analytics workspace name."
  type        = string
}

variable "workspace_retention_in_days" {
  description = "Approved Log Analytics retention in days."
  type        = number
  default     = 90

  validation {
    condition     = var.workspace_retention_in_days >= 30 && var.workspace_retention_in_days <= 730
    error_message = "Workspace retention must be between 30 and 730 days; verify the current Azure service limits and policy."
  }
}

variable "operator_email" {
  description = "Approved, staffed on-call email address for Azure Monitor alerts."
  type        = string
}

variable "pool_metric_alert_thresholds" {
  description = "Approved average elastic-pool saturation thresholds (percent) for CPU, data read, log write, workers, sessions, and storage."
  type        = map(number)
  default = {
    cpu_percent                = 80
    physical_data_read_percent = 80
    log_write_percent          = 80
    workers_percent            = 80
    sessions_percent           = 80
    storage_percent            = 85
  }

  validation {
    condition = length(var.pool_metric_alert_thresholds) == 6 && alltrue([
      for metric in [
        "cpu_percent",
        "physical_data_read_percent",
        "log_write_percent",
        "workers_percent",
        "sessions_percent",
        "storage_percent"
      ] :
      contains(keys(var.pool_metric_alert_thresholds), metric) &&
      try(var.pool_metric_alert_thresholds[metric], 0) > 0 &&
      try(var.pool_metric_alert_thresholds[metric], 0) <= 100
    ])
    error_message = "Set approved 0-100 percent thresholds for cpu_percent, physical_data_read_percent, log_write_percent, workers_percent, sessions_percent, and storage_percent."
  }
}

variable "diagnostic_log_categories" {
  description = "Approved SQL diagnostic categories to export when the target resource supports them; review volume, sensitivity, and cost."
  type        = set(string)
  default = [
    "DatabaseWaitStatistics",
    "Deadlocks",
    "Errors",
    "QueryStoreRuntimeStatistics",
    "QueryStoreWaitStatistics",
    "SQLSecurityAuditEvents",
    "Timeouts"
  ]

  validation {
    condition = length(var.diagnostic_log_categories) > 0 && alltrue([
      for category in var.diagnostic_log_categories :
      contains([
        "AutomaticTuning",
        "Blocks",
        "DatabaseWaitStatistics",
        "Deadlocks",
        "DevOpsOperationsAudit",
        "DmsWorkers",
        "Errors",
        "ExecRequests",
        "QueryStoreRuntimeStatistics",
        "QueryStoreWaitStatistics",
        "RequestSteps",
        "SQLInsights",
        "SQLSecurityAuditEvents",
        "Timeouts",
        "Waits"
      ], category)
    ])
    error_message = "Use one or more supported Azure SQL diagnostic categories; verify category availability for each resource type."
  }
}

variable "tags" {
  description = "Organization-approved resource ownership, environment, and cost-allocation tags."
  type        = map(string)

  validation {
    condition = alltrue([
      for required_tag in ["environment", "serviceOwner", "costCenter", "dataClassification"] :
      try(trimspace(var.tags[required_tag]), "") != "" &&
      !strcontains(lower(try(var.tags[required_tag], "")), "replace-with")
    ])
    error_message = "Include non-empty environment, serviceOwner, costCenter, and dataClassification tags."
  }
}
