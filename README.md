# Azure SQL Elastic Pool Production Deployment

A cost-free production planning and deployment repository for Azure SQL
Database elastic pools. It contains a gated implementation plan, environment
input workbook, architecture and lifecycle diagrams, prerequisite/remediation
guides, an infrastructure-as-code template, and an approval-gated Azure DevOps
pipeline. No Azure resources are created by preparing or validating this repo.

- **Start here:** [Production deployment runbook](docs/production-deployment-runbook.md)
- **Readiness plan:** [Production plan, workstreams, gates, and exit criteria](docs/production-readiness-plan.md)
- **Environment worksheet:** [All environment-specific inputs and approvals](docs/environment-inputs.md)
- **Printable guide:** [Download the PDF](docs/Azure-SQL-Elastic-Pool-Operations-Runbook.pdf)
- **Architecture:** [Reference design and trust boundaries](docs/architecture.md)
- **Diagrams:** [Diagram sources](diagrams/README.md)
- **Operations:** [SQL elastic pool operating procedures](docs/azure-sql-elastic-pool-operations-runbook.md)
- **Terraform:** [`terraform/production`](terraform/production/README.md)
- **Azure DevOps:** [`azure-pipelines.yml`](azure-pipelines.yml)

## What this deploys

The Terraform root module provisions an Azure SQL logical server configured for
Microsoft Entra-only authentication and disabled public network access;
configurable vCore elastic pools and pooled databases; a Private Endpoint to an
existing VNet subnet and Private DNS zone; Log Analytics; diagnostic settings
for the server, master database, pools, and databases; server auditing to
Log Analytics; an email action group; and per-pool CPU and data-I/O metric
alerts.

The VNet, Private Endpoint subnet, Private DNS zones and VNet links,
state-storage account, identity, role assignments, Azure DevOps project,
approvals, and production decisions remain explicit prerequisites. Keeping
these shared controls outside the application stack avoids silently changing
network or identity foundations during a database deployment.

## Quick start

1. Read the full [prerequisite checklist and resolution guide](docs/production-deployment-runbook.md#1-prerequisite-readiness-gates).
2. Complete the architecture, sizing, identity, network, security, backup,
   recovery, and cost decisions with the named service owners.
3. Bootstrap the remote Terraform state account and configure the workload
   identity, RBAC, private networking, and Azure DevOps environment approvals.
4. Record approved values in the [environment worksheet](docs/environment-inputs.md).
   The tracked
   [`prod.tfvars.example`](terraform/production/environments/prod.tfvars.example)
   is deliberately invalid and must not be used as deployment input.
5. Run credential-free checks. Do not run an authenticated plan until a
   subscription, identity, state backend, and change approval are available.
   Later follow the
   [deployment runbook](docs/production-deployment-runbook.md#6-validate-and-plan).
6. Configure the pipeline variable group and service connection, then run the
   Azure DevOps pipeline. Production `apply` is gated by the `sql-prod`
   environment approval and applies the exact reviewed plan artifact.
7. Complete all post-deployment acceptance, restore, monitoring, and handover
   checks before onboarding production databases.

## Important production boundary

This repository is a production-oriented **plan and implementation template**,
not a deployed or production-certified service. It has no subscription,
tenant, approved network, workload measurements, or organization approvals
associated with it. Example sizing, region, alert thresholds, retention, SKUs,
and names are not real environment decisions. Repository preparation and
credential-free checks create no Azure resources and incur no Azure resource
charges; do not run an authenticated Terraform plan or apply until the input
workbook, gates, RBAC, and change approval are complete. A later Azure
deployment may incur charges.

Complete the [readiness plan](docs/production-readiness-plan.md) and
[environment worksheet](docs/environment-inputs.md), then obtain workload,
compliance, quota, cost, RPO/RTO, and change-control approvals. Test in a
nonproduction environment, inspect the saved production plan, and complete
restore and failover exercises before production use. A production-ready plan
does not make the actual Azure environment production-ready by itself.

The source repository's Bicep sample is retained for reference. Terraform is
the primary implementation for this deployment kit; do not deploy both
templates to manage the same resources.

## Local checks and PDF

Requirements: Terraform CLI matching the version pinned in
`azure-pipelines.yml`, Node.js 18+, and Git. Azure CLI and approved Azure
credentials are required only for later, authorized environment discovery,
state bootstrap, and authenticated planning. The following local checks do not
authenticate to Azure or create Azure resources. Terraform initialization
downloads the pinned provider from its configured registry or mirror.

```powershell
terraform -chdir=terraform/production fmt -check -recursive
terraform -chdir=terraform/production init -backend=false
terraform -chdir=terraform/production validate
bash -n scripts/terraform-ado.sh
node scripts/build-pdf.mjs
```

The generated PDF is checked into `docs/` and rebuilt by CI from the readiness
plan, environment worksheet, and production deployment runbook. Detailed
operational procedures remain in
[`docs/azure-sql-elastic-pool-operations-runbook.md`](docs/azure-sql-elastic-pool-operations-runbook.md).
The Terraform provider lock file includes checksums for the Linux pipeline
agent and Windows local validation.
