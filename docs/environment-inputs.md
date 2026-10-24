# Azure SQL production environment inputs and approval worksheet

This worksheet is intentionally unfilled. No Azure subscription, tenant,
workload, region, organization, service owner, network, budget, or approval was
provided for this repository. `TBD` is a planning status—not a Terraform value
and not authorization to deploy. Never invent values to make the template
validate.

Complete it through the approved change/design process. Keep credentials,
tokens, passwords, private certificates, customer data, private connection
strings, and sensitive topology out of Git and this worksheet. Record only
non-secret resource identifiers here if the repository's access classification
permits them; otherwise keep the completed copy in the approved restricted
configuration system.

| Document field | Value |
| --- | --- |
| Service/application name | `TBD` |
| Document owner / reviewer | `TBD` |
| Version / review date | `TBD` |
| Change or architecture decision reference | `TBD` |
| Status | `NOT APPROVED FOR DEPLOYMENT` |

## 1. Scope, ownership, and impact

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| Business service and application(s) | `TBD` | Service owner |
| Business criticality and user impact | `TBD` | Service owner |
| Database inventory and source systems | `TBD` | Application owner + DBA |
| Database count, growth and onboarding sequence | `TBD` | DBA |
| Database/application technical owner per item | `TBD` | Application owner |
| Service hours, support model and on-call rotation | `TBD` | Operations |
| Planned maintenance windows and prohibited dates | `TBD` | Service owner |
| Data residency, classification and regulatory boundary | `TBD` | Security/compliance |
| Service dependencies and downstream consumers | `TBD` | Application owner |
| Change owner, implementer, independent reviewer | `TBD` | Change manager |
| Go/no-go authority and stop/rollback decision owner | `TBD` | Change manager |

## 2. Tenant, subscription, location, and resource scope

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| Entra tenant ID (GUID) | `TBD` | Identity/platform |
| Azure subscription ID (GUID) | `TBD` | Subscription owner |
| Subscription display name / management group | `TBD` | Cloud platform |
| Primary region and allowed paired/recovery region | `TBD` | Architecture + compliance |
| Application resource group name and owner | `TBD` | Cloud platform |
| Resource naming convention and uniqueness check | `TBD` | Cloud platform |
| Required resource providers registered | `TBD` | Subscription owner |
| Azure Policy assignments/exemptions | `TBD` | Governance |
| Region/SKU quota evidence and quota request reference | `TBD` | Capacity owner |
| Deployment identity's exact RBAC roles and scopes | `TBD` | Cloud security |
| Budget, cost center and alert recipient | `TBD` | FinOps |

## 3. Workload discovery and pool design

Attach a protected inventory/profile for each workload class. Do not put
customer queries, row data, PII, or secrets in this repository.

| Profile field | Evidence/status |
| --- | --- |
| Collection period and representativeness (including peak/seasonal events) | `TBD` |
| Per-database size now, growth rate, and forecast horizon | `TBD` |
| Peak/p95/p99 CPU, data I/O, log I/O, workers, sessions, concurrency | `TBD` |
| Query latency/throughput objectives and observed baselines | `TBD` |
| Batch, month-end, reporting, ETL and deployment peaks | `TBD` |
| Workload classes, noisy-neighbor analysis and isolation needs | `TBD` |
| Database-to-pool mapping and owner for every database | `TBD` |
| vCore/DTU model and service tier decision with feature rationale | `TBD` |
| SKU name, hardware family and license eligibility evidence | `TBD` |
| Per-pool capacity, storage cap, and headroom basis | `TBD` |
| Per-database minimum/maximum resource bounds and fairness rationale | `TBD` |
| Zone redundancy decision and region/SKU support evidence | `TBD` |
| Elastic pool/database limits and Azure service-limit review | `TBD` |
| Nonproduction load-test plan/results and acceptance criteria | `TBD` |
| Expected growth/capacity review triggers | `TBD` |

### Pool inventory to be approved

| Pool key | Workload class | Region | Tier / SKU / family | Capacity and storage | Database map and limits | Zone redundant? | Evidence / approval |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TBD` | `TBD` | `TBD` | `TBD` | `TBD` | `TBD` | `TBD` | `TBD` |

Repeat the row for every pool. Use real Terraform keys only after owners approve
the mapping and measurements.

## 4. Network, private DNS, and name resolution

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| Hub/spoke or landing-zone architecture reference | `TBD` | Network architect |
| VNet and region | `TBD` | Network |
| Private Endpoint subnet resource ID and available IP capacity | `TBD` | Network |
| Subnet Private Endpoint policy/NSG/route requirements | `TBD` | Network/security |
| Existing Private DNS zone `privatelink.database.windows.net` resource ID | `TBD` | DNS owner |
| Private DNS VNet links and resolver/forwarding design | `TBD` | DNS owner |
| Application subnet(s), routes and TCP 1433 allowance | `TBD` | Network/security |
| Private endpoint approval/role requirement | `TBD` | Network/platform |
| Private DNS resolution test from each application path | `TBD` | App/network |
| Private DNS and TCP test from deployment agent | `TBD` | DevOps/network |
| Explicit statement that public SQL access remains disabled | `TBD` | Security |

## 5. Identity, security, and compliance

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| Entra SQL administrator group display name | `TBD` | Identity/DBA |
| Entra SQL administrator group object ID (non-zero GUID) | `TBD` | Identity |
| Tenant match verified for that group | `TBD` | Identity |
| Application managed identities / Entra groups and database roles | `TBD` | App owner + DBA |
| Human DBA operator groups, PIM and access-review cadence | `TBD` | Identity/security |
| Azure DevOps service connection name and federated subject | `TBD` | DevOps/identity |
| Exact deployment RBAC actions and resource scopes | `TBD` | Cloud security |
| Private state backend data-plane RBAC principal/scope | `TBD` | IaC platform |
| TLS/client driver requirements and connection validation | `TBD` | Security/app |
| TDE/platform encryption and key-management requirement | `TBD` | Security/compliance |
| Defender for SQL and vulnerability/security monitoring policy | `TBD` | Security |
| Auditing destination, access, retention and review owner | `TBD` | Security/compliance |
| Data deletion, legal hold, restore isolation and evidence retention | `TBD` | Compliance/DBA |
| Threat model, risk acceptance and exception record | `TBD` | Security |

Never add a SQL administrator password. The current Terraform template enables
Microsoft Entra-only authentication; confirm that this is compatible with all
approved clients before deployment.

## 6. Backup, recovery, and continuity

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| RPO per service/workload class | `TBD` | Service owner |
| RTO per service/workload class | `TBD` | Service owner |
| Point-in-time restore retention per database | `TBD` | DBA/compliance |
| Backup redundancy setting and regional residency approval | `TBD` | DBA/compliance |
| Long-term retention / legal hold requirements and implementation | `TBD` | Compliance |
| Recovery region, subscription, quota and secondary pool sizing | `TBD` | Platform + DBA |
| Geo-replication/failover-group topology and supported feature review | `TBD` | DBA/architecture |
| Listener, private DNS, endpoint and app retry behavior after failover | `TBD` | App/network |
| Restore target isolation and required access approvals | `TBD` | Security/DBA |
| Restore test date, dataset class, integrity checks and measured RTO | `TBD` | DBA |
| Planned and forced failover authority and criteria | `TBD` | Incident commander |
| Recurring recovery drill cadence and evidence owner | `TBD` | Service owner |

## 7. State backend and delivery platform

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| State resource group, subscription and region | `TBD` | IaC platform |
| Globally unique StorageV2 account name / redundancy | `TBD` | IaC platform/FinOps |
| Blob container and unique, stable state key | `TBD` | IaC platform |
| Private Blob endpoint, DNS zone/link and agent reachability | `TBD` | Network |
| Public access disabled, shared key disabled, TLS policy | `TBD` | Security |
| Versioning, deletion recovery, lock and backup/restore policy | `TBD` | IaC platform |
| State access groups, pipeline data-plane role and scope | `TBD` | Cloud security |
| Azure DevOps project, repo and protected `main` rules | `TBD` | DevOps |
| Linux agent pool, owner, patching, egress and private DNS | `TBD` | DevOps |
| Terraform CLI version and approved provider registry/mirror | `TBD` | IaC platform |
| Provider version and committed `.terraform.lock.hcl` review | `TBD` | IaC reviewer |
| Variable group name and authorized pipelines | `TBD` | DevOps |
| `sql-prod` environment approvers/checks and access controls | `TBD` | Change manager |
| Server-side branch control on production service connection | `TBD` | DevOps/security |
| Plan artifact retention, access and sensitivity classification | `TBD` | DevOps/security |

Do not record storage keys, SAS tokens, OIDC tokens, client secrets, private
keys, or Terraform state in this worksheet, Git, pipeline YAML, or plan output.

## 8. Monitoring, service levels, and operations

| Input | Approved value / evidence reference | Accountable approver |
| --- | --- | --- |
| Log Analytics workspace name, region and access mode | `TBD` | Observability |
| Workspace retention, data export, access and cost controls | `TBD` | Observability/compliance |
| Diagnostic categories and destination verification per resource type | `TBD` | Observability/DBA |
| CPU, data I/O, log I/O, storage, worker/session alert thresholds | `TBD` | DBA + SRE |
| Alert evaluation window, frequency, severity and action policy | `TBD` | SRE |
| Staffed action group receiver and test evidence | `TBD` | Operations |
| Dashboards/workbook and required fleet/database drilldowns | `TBD` | SRE/DBA |
| SLI/SLO, user-facing availability/performance objectives | `TBD` | Service owner |
| Incident severity, escalation matrix and support contracts | `TBD` | Operations |
| Cost monitoring and budget threshold policy | `TBD` | FinOps |
| Routine access, policy, capacity, cost and alert review cadence | `TBD` | Service owner |
| Inventory/CMDB and ownership update process | `TBD` | Operations |

## 9. Required cost estimate

Record estimate source, date, currency, term, region, assumptions and reviewer.
Use the current Azure pricing calculator and organization-specific agreements;
no numeric price is supplied by this repository.

| Cost line | Quantity / assumptions | Monthly estimate | Reviewer / evidence |
| --- | --- | --- | --- |
| Primary elastic pools and vCore/license | `TBD` | `TBD` | `TBD` |
| Database storage and growth | `TBD` | `TBD` | `TBD` |
| Backup redundancy and retention | `TBD` | `TBD` | `TBD` |
| Log Analytics ingestion and retention | `TBD` | `TBD` | `TBD` |
| Azure Monitor alerting/action groups | `TBD` | `TBD` | `TBD` |
| Private endpoints, DNS, network transfer | `TBD` | `TBD` | `TBD` |
| Secondary region, replication and failover capacity | `TBD` | `TBD` | `TBD` |
| Support, nonproduction and test/restore resources | `TBD` | `TBD` | `TBD` |
| Total estimate, contingency and budget approval | `TBD` | `TBD` | `TBD` |

## 10. Terraform input map

The following correspond to the current `terraform/production` module.
Populate the actual reviewed configuration only after the preceding decisions
are approved. The existing `terraform.tfvars.example` contains illustrative
values and is not production input.

| Terraform input | Source / validation before use |
| --- | --- |
| `resource_group_name` | Approved dedicated application resource group and owner. |
| `location` | Approved primary region; confirm every selected feature/SKU is available there. |
| `sql_server_name` | Globally unique lowercase letters/digits, 1-63 characters; confirm naming policy and availability. |
| `sql_entra_admin_login` | Approved Entra admin group display name. |
| `sql_entra_admin_object_id` | Verified, non-zero Entra group GUID in the target tenant. |
| `private_endpoint_subnet_id` | Exact network-approved subnet resource ID; permissions and address capacity verified. |
| `private_dns_zone_id` | Exact existing `privatelink.database.windows.net` zone resource ID; VNet link and DNS tested. |
| `pools` | Evidence-based workload map, tier/SKU/family/license/capacity/storage/per-database bounds/zone redundancy. |
| `databases` | Approved database names, pool assignments, storage ceilings, backup retention/redundancy. |
| `workspace_name` | Globally unique, policy-compliant workspace name and ownership. |
| `workspace_retention_in_days` | Approved range and cost/compliance review; default is not an approval. |
| `operator_email` | Staffed, tested, approved operational email. |
| `pool_cpu_alert_threshold` | DBA/SRE-tuned value with evaluation policy and action response. |
| `pool_data_io_alert_threshold` | DBA/SRE-tuned value with evaluation policy and action response. |
| `tags` | Organization-approved environment, service owner, cost center, data classification and required tags. |

Review this table against `variables.tf` whenever module inputs change.
Terraform variable values must not contain credentials.

## 11. Approval record and final no-go conditions

| Decision | Approver/name | Date | Evidence/change reference | Status |
| --- | --- | --- | --- | --- |
| Service owner / scope | `TBD` | `TBD` | `TBD` | Pending |
| Capacity and SKU | `TBD` | `TBD` | `TBD` | Pending |
| Cost/budget | `TBD` | `TBD` | `TBD` | Pending |
| Network/DNS | `TBD` | `TBD` | `TBD` | Pending |
| Identity/RBAC/security | `TBD` | `TBD` | `TBD` | Pending |
| Backup/recovery/compliance | `TBD` | `TBD` | `TBD` | Pending |
| DevOps/state/pipeline controls | `TBD` | `TBD` | `TBD` | Pending |
| Operations/on-call/alerting | `TBD` | `TBD` | `TBD` | Pending |
| Nonproduction validation | `TBD` | `TBD` | `TBD` | Pending |
| Production change and exact plan approval | `TBD` | `TBD` | `TBD` | Pending |

**No-go:** Any `TBD` in a required production input; absent evidence or owner;
unapproved exception; unknown subscription/tenant; cost or quota uncertainty;
failed private DNS/agent connectivity; missing protected approvals; unreviewed
plan; missing restore evidence; or an action that creates an unapproved
replacement, deletion, public path, or permission expansion.

## 12. External references to verify at implementation time

- [Azure SQL elastic pool overview](https://learn.microsoft.com/azure/azure-sql/database/elastic-pool-overview)
- [Azure SQL elastic pool management](https://learn.microsoft.com/azure/azure-sql/database/elastic-pool-manage)
- [Azure SQL networking/private endpoints](https://learn.microsoft.com/azure/azure-sql/database/private-endpoint-overview)
- [Azure SQL backup and restore](https://learn.microsoft.com/azure/azure-sql/database/automated-backups-overview)
- [Azure SQL failover groups](https://learn.microsoft.com/azure/azure-sql/database/failover-group-sql-db)
- [AzureRM Terraform provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AzureRM backend authentication](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [Azure DevOps workload identity federation](https://learn.microsoft.com/azure/devops/pipelines/release/configure-workload-identity)
- [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/)
