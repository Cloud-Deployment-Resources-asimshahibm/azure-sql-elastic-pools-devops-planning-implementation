# Azure SQL Elastic Pool Operations

Architecture, provisioning guidance, monitoring, alerting, and day-to-day
support for an Azure SQL Database estate with 10+ elastic pools and 100+
databases.

**Runbook PDF:** [Download the PDF](docs/Azure-SQL-Elastic-Pool-Operations-Runbook.pdf)  
**Full runbook:** [Read the Markdown runbook](docs/azure-sql-elastic-pool-operations-runbook.md)  
**Architecture:** [Open the architecture diagram and component guide](docs/architecture.md)

## Repository layout

```text
.
├── README.md
├── docs/
│   ├── Azure-SQL-Elastic-Pool-Operations-Runbook.pdf
│   ├── architecture.md
│   └── azure-sql-elastic-pool-operations-runbook.md
├── infra/
│   └── monitoring/
│       └── main.bicep
└── scripts/
    └── build-pdf.mjs
```

## Quick start

1. Read the [runbook](docs/azure-sql-elastic-pool-operations-runbook.md) and
   agree on workload ownership, service objectives, recovery objectives, and
   alert responders before changing production.
2. Deploy the monitoring baseline in `infra/monitoring/main.bicep` to a
   dedicated monitoring resource group. Supply an approved on-call email.
3. Inventory and classify the SQL logical servers, elastic pools, and
   databases. Configure diagnostic settings on **both** pool and database
   resources.
4. Create metric alerts, the Azure Monitor Workbook, and action group routing
   using the runbook. Tune thresholds against workload baselines.
5. Apply infrastructure changes through reviewed IaC and change control; test
   restore and regional recovery before relying on them.

The included Bicep file creates only a Log Analytics workspace and an email
action group. It does not create SQL servers, pools, databases, private
endpoints, diagnostic settings, alert rules, or a workbook. Those require
environment-specific decisions and are covered in the runbook.

All names, regions, capacities, thresholds, retention periods, and sample
resource groups in this project are examples or starting points. Confirm
regional SKU availability, quotas, compliance requirements, workload baselines,
and the current Azure price before production deployment.

## Build the monitoring baseline

Install Azure CLI and Bicep, authenticate with an approved identity, and create
the resource group. Then deploy:

```bash
az login
az account set --subscription "<subscription-id>"
az group create --name "rg-sql-monitoring-prod" --location "eastus"

az deployment group create \
  --resource-group "rg-sql-monitoring-prod" \
  --template-file "infra/monitoring/main.bicep" \
  --parameters location="eastus" \
               workspaceName="law-sql-prod" \
               actionGroupName="ag-sql-oncall-prod" \
               operatorEmail="dba-oncall@example.com"
```

Replace the sample subscription, region, names, and email. Continue with the
configuration and validation steps in the runbook.

## Build the PDF locally

Node.js 18 or later is required. No npm dependencies are used:

```bash
node scripts/build-pdf.mjs
```

The script renders the Markdown runbook and a vector architecture diagram to
`docs/Azure-SQL-Elastic-Pool-Operations-Runbook.pdf`.

## Scope and safety

This is an operational reference, not a workload-specific capacity guarantee.
Do not blindly apply example alert thresholds or pool sizes. Validate every
scale, database move, firewall/network change, restore, and failover against
the application owner, maintenance window, cost approval, and recovery plan.

## Microsoft references

- [Azure SQL elastic pools overview](https://learn.microsoft.com/azure/azure-sql/database/elastic-pool-overview)
- [Manage elastic pools](https://learn.microsoft.com/azure/azure-sql/database/elastic-pool-manage)
- [Monitor Azure SQL with metrics and alerts](https://learn.microsoft.com/azure/azure-sql/database/monitoring-metrics-alerts)
- [Elastic pool metric reference](https://learn.microsoft.com/azure/azure-monitor/reference/supported-metrics/microsoft-sql-servers-elasticpools-metrics)
- [Export Azure SQL metrics and diagnostic telemetry](https://learn.microsoft.com/azure/azure-sql/database/metrics-diagnostic-telemetry-logging-streaming-export-configure)
- [Azure Workbooks overview](https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [Azure SQL Database failover groups](https://learn.microsoft.com/azure/azure-sql/database/failover-group-sql-db)
