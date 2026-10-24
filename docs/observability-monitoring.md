# Built-in observability and monitoring

The Terraform implementation includes a Log Analytics workspace, SQL
auditing, diagnostic settings on the logical server, `master`, every elastic
pool and every managed database, an Azure Monitor workbook, a staffed email
action group, and six saturation metric alerts per pool. Observability is
managed with the database stack; it is not only an external recommendation.

This is a configurable baseline, not a tuned SLO. Thresholds, diagnostic
categories, retention, access, notification routing, ingestion volume, and
cost must be approved for the real environment. No Azure telemetry is
collected while preparing or validating this repository.

## Provisioned monitoring surfaces

| Surface | Terraform implementation | Coverage and operational use |
| --- | --- | --- |
| Log Analytics | `azurerm_log_analytics_workspace.sql` | Dedicated destination; region and retention are environment inputs. Review access, ingestion, retention, query, and archive costs. |
| SQL auditing | `azurerm_mssql_server_extended_auditing_policy.sql` | Enables SQL audit log monitoring to the configured diagnostic destination; confirm audit policy, access, destination tables, and compliance retention in the target tenant. |
| Diagnostic settings | Server, `master`, every pool, and every database | Selects approved log categories and exports `AllMetrics` when supported. Category selection is intersected with categories exposed by each actual resource. |
| Metric alerts | `azurerm_monitor_metric_alert.pool_saturation` | Six rules for each pool; every rule routes to the configured action group. |
| On-call action group | `azurerm_monitor_action_group.sql_oncall` | Common alert schema email receiver; replace the example with a staffed, monitored and tested response destination. |
| Operations workbook | `azurerm_application_insights_workbook.sql_operations` | Log Analytics-backed trend chart and latest-sample table for the elastic-pool utilization metrics. |
| Terraform outputs | Workbook, workspace and alert resource IDs | Lets the release/handover process link directly to the provisioned observability resources. |

## Per-pool alert coverage

The Azure Monitor metric reference identifies these as elastic-pool platform
metrics. Alert values are average percentages over a 5-minute window, evaluated
every minute. Azure metric alerts use the REST metric identifier in the table;
the workbook filters the corresponding `AzureMetrics.MetricName` display names.
The example threshold map is deliberately illustrative and must be tuned to
the workload by the DBA/SRE. The alert uses severity 2; change severity and
response policy through an approved review.

| Signal | Azure metric name | Why monitor it |
| --- | --- | --- |
| CPU | `cpu_percent` (workbook display name: `CPU percentage`) | Compute saturation and sustained workload pressure. |
| Physical data reads | `physical_data_read_percent` (display name: `Data IO percentage`) | Data-I/O pressure. This is the Azure metric identifier; do not use `data_io_percent`. |
| Transaction log writes | `log_write_percent` (display name: `Log IO percentage`) | Log throughput pressure and write/batch bottlenecks. |
| Workers | `workers_percent` (display name: `Workers percentage`) | Worker exhaustion and connection/request capacity pressure. |
| Sessions | `sessions_percent` (display name: `Sessions percentage`) | Session-capacity pressure and connection-pool behavior. |
| Storage | `storage_percent` (display name: `Data space used percent`) | Pool storage headroom; alert before the service/database ceiling is reached. |

Thresholds are provided by `pool_metric_alert_thresholds`. Exactly these six
metric keys are accepted, each with a value greater than 0 and at most 100.
Current illustrative defaults are 80 percent for CPU, reads, log writes,
workers and sessions, and 85 percent for storage; these values are not an
approved production tuning. A single pool produces six alert rules.

Pool-level metrics can hide a hot individual database. Use the workbook, SQL
diagnostic categories, Query Store, application telemetry, and workload-level
analysis to investigate. Avoid automatic scaling based on one transient
measurement; follow the capacity/change process.

## Workbook

Terraform creates **Azure SQL Elastic Pool Operations** in Azure Monitor
Workbooks, scoped to the configured Log Analytics workspace. It includes:

- A 24-hour trend view for CPU, physical data reads, log writes, workers,
  sessions, and storage by pool.
- The latest metric samples by pool resource ID and metric name.

The workbook is an operational starting view. Confirm that the workbook is
visible to the intended operators, the workspace contains samples, the time
range and resource filters are suitable for the workload, and queries execute
with the operator's permissions. Add approved app-level latency, request
correlation, deployment annotations, and SLO panels in a reviewed extension;
those signals must be instrumented by the application and are not generated by
the SQL infrastructure module.

## Diagnostic categories and data handling

The default category selection is:

- `SQLSecurityAuditEvents`
- `Errors`, `Deadlocks`, and `Timeouts`
- `DatabaseWaitStatistics`
- `QueryStoreRuntimeStatistics` and `QueryStoreWaitStatistics`

Only categories both explicitly selected in `diagnostic_log_categories` and
reported as available for a specific server/database/pool are enabled for that
resource. This avoids assuming every SQL diagnostic category exists on every
resource type. Confirm actual destinations, table schemas and event arrival in
the target region/provider version; SQL resource-specific log tables may differ
by destination mode. Audit and Query Store data can include sensitive workload
metadata. Apply least-privilege workspace access, approved retention, data
classification, and cost controls. Add categories only with an explicit
security/compliance and ingestion-cost review.

Terraform exports logs and all available platform metrics only for the selected
category/diagnostic destination. It does not export application traces, SQL
query text as a substitute for Query Store controls, or customer data into this
repository. A diagnostic setting is not proof that ingestion works: acceptance
requires observing fresh representative events/metrics in Azure Monitor.

## Alert response and acceptance

For each firing pool alert:

1. Identify the pool, metric, threshold, evaluation window and affected
   applications. Confirm user impact and the alert's current state before
   taking action.
2. Open the operations workbook and compare the trend across the other pool
   signals. Identify whether pressure is pool-wide or driven by one database.
3. Check recent deployments, application retry/concurrency behavior, batch
   peaks, Query Store regressions, database-level limits, storage growth, and
   Azure Service Health.
4. Engage the DBA and application owner. For sustained risk, prepare a reviewed
   capacity or pool-placement change with cost, quota and recovery-region
   impact. Do not make an unreviewed scale or failover change during incident
   response.
5. Record alert/incident IDs, impact, samples, decision owner, action,
   acknowledgement, resolution and follow-up. Tune a threshold only through a
   documented DBA/SRE review with representative workload evidence.

Before service acceptance:

- Verify diagnostics on server, `master`, every pool and every database.
- Verify the intended categories and destination/table mode and observe new
  telemetry from each resource class.
- Confirm each pool has all six metric alerts with approved threshold,
  severity, 1-minute evaluation frequency, 5-minute window and the correct
  action group.
- Trigger notification through an approved nonproduction test and capture
  delivery, acknowledgement, escalation and closure evidence. Do not generate
  noisy/false production incidents to test routing.
- Open the workbook as an operator and verify meaningful trend and latest
  sample results; a blank panel is a failed check until explained.
- Verify retention, workspace access, audit access, cost reporting, and the
  incident/on-call owner.
- Confirm application teams own and test their request latency, failure rate,
  dependency health and trace correlation telemetry.

## Cost, limits and operations

Workspace ingestion/retention and log-query costs depend on volume and current
pricing; metric alert rules/workbook features may also have service-specific
limits or charges. Estimate costs with real workload profiles. Set Azure
budgets and usage alerts at the organization-approved subscription scope; the
workspace retention setting is not a budget or an ingestion cap. Do not
silently cap or discard required audit/security telemetry to reduce cost.

Alert count grows as **six times the number of configured pools**. Check Azure
Monitor quotas, notification limits, receiver ownership, alert-rule naming,
and action-group policies before scaling to a large pool fleet. If the fleet
exceeds this starter's scope, design alert grouping, dynamic thresholds, action
routing and workbook filters without losing per-pool accountability.

Review metric names, diagnostic categories, AzureRM schemas, workspace tables,
regional support and pricing against the current Microsoft references linked
below before a provider/service upgrade. Confirm signals remain live after
every deployment, workspace change, pool change, and recovery exercise.

## References

- [Supported elastic-pool metrics](https://learn.microsoft.com/azure/azure-monitor/reference/supported-metrics/microsoft-sql-servers-elasticpools-metrics)
- [Supported SQL database log categories](https://learn.microsoft.com/azure/azure-monitor/reference/supported-logs/microsoft-sql-servers-databases-logs)
- [Azure SQL metrics and alerts](https://learn.microsoft.com/azure/azure-sql/database/monitoring-metrics-alerts)
- [Azure Monitor Workbooks](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Azure Monitor diagnostic settings](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings)
- [Azure Monitor pricing](https://azure.microsoft.com/pricing/details/monitor/)
