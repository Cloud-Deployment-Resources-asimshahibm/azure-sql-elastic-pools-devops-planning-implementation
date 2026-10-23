# Terraform deployment root

This root provisions an Entra-only Azure SQL logical server with public network
access disabled, configured vCore elastic pools/databases, a SQL Private
Endpoint using existing subnet and Private DNS zone IDs, Log Analytics,
server auditing, server/master/pool/database diagnostic settings, an email
action group, and per-pool CPU/data-I/O alerts.

It intentionally does not provision shared networking, the Azure Storage
backend, identity/RBAC, Azure DevOps resources, or a DR topology. Complete the
[production deployment prerequisites](../../docs/production-deployment-runbook.md)
before running an authenticated plan.

## Configuration

1. Copy `terraform.tfvars.example` to `environments/prod.tfvars` after creating
   that directory, then replace every sample with reviewed environment values.
   Do not put secrets in the file.
2. Set backend values and identity authentication through the Azure DevOps
   variable group and OIDC service connection; do not put backend credentials
   in Terraform files.
3. Verify SKU, region, capacity, alert, retention, tag, and cost decisions with
   the responsible owners. Sample values are not sizing advice.
4. Initialize from an approved network, review and commit the generated
   `.terraform.lock.hcl` with Linux (and Windows, if used) checksums. The
   provider version is pinned in `versions.tf`; the lock file records verified
   package checksums.

## Credential-free validation

```powershell
terraform -chdir=terraform/production fmt -check -recursive
terraform -chdir=terraform/production init -backend=false
terraform -chdir=terraform/production validate
```

Do not use an unreviewed local state for production. The pipeline initializes
the AzureRM backend with Microsoft Entra data-plane auth and OIDC, creates a
saved plan, and applies that exact artifact only after the protected
`sql-prod` Environment approves.

Initialization needs approved network access to the Terraform Registry or
organization provider mirror, even though the checks do not need Azure access.

Terraform state and saved plan files can expose infrastructure details. Keep
both private, restrict access, and follow the organization's retention policy.
