# Azure SQL Elastic Pool Production Deployment

A production-oriented design and deployment kit for Azure SQL Database elastic
pools. It includes a detailed prerequisite and recovery checklist, a reference
architecture, Terraform for the SQL and monitoring baseline, an approval-gated
Azure DevOps pipeline, and a printable deployment runbook.

- **Start here:** [Production deployment runbook](docs/production-deployment-runbook.md)
- **Printable guide:** [Download the PDF](docs/Azure-SQL-Elastic-Pool-Operations-Runbook.pdf)
- **Architecture:** [Reference design and trust boundaries](docs/architecture.md)
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
4. Copy `terraform/production/terraform.tfvars.example` to a protected
   environment-specific `.tfvars` file; replace every example value and review
   it. Never put passwords, tokens, or other secrets in Terraform variables.
5. Run the local validation and plan steps in the
   [deployment runbook](docs/production-deployment-runbook.md#5-validate-and-plan).
6. Configure the pipeline variable group and service connection, then run the
   Azure DevOps pipeline. Production `apply` is gated by the `sql-prod`
   environment approval and applies the exact reviewed plan artifact.
7. Complete all post-deployment acceptance, restore, monitoring, and handover
   checks before onboarding production databases.

## Important production boundary

This is a reviewed starting implementation, not a claim that any default pool
size, alert threshold, region, retention period, SKU, or network layout is
right for a particular workload. No workload has been deployed or capacity
tested by publishing this repository. Obtain the required workload, compliance,
quota, cost, RPO/RTO, and change-control approvals; substitute the approved
values; test in a nonproduction environment; inspect the saved plan; and
complete the documented restore and failover exercises before production use.

The source repository's Bicep sample is retained for reference. Terraform is
the primary implementation for this deployment kit; do not deploy both
templates to manage the same resources.

## Local checks and PDF

Requirements: Terraform CLI matching the version pinned in `azure-pipelines.yml`,
Node.js 18+, and Git. Azure CLI is needed for authenticated planning and the
state bootstrap procedure; the format/validate checks do not require Azure
credentials.

```powershell
terraform -chdir=terraform/production fmt -check -recursive
terraform -chdir=terraform/production init -backend=false
terraform -chdir=terraform/production validate
node scripts/build-pdf.mjs
```

The generated PDF is checked into `docs/` and rebuilt by CI. Its source is
`docs/production-deployment-runbook.md`.
