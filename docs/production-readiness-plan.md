# Azure SQL elastic pool production readiness plan

## Document control

| Field | Value |
| --- | --- |
| Status | Planning baseline; environment-specific decisions are intentionally pending. |
| Scope | Azure SQL Database elastic pools, Terraform, private networking, Azure DevOps delivery, monitoring, operations, and recovery. |
| Cost boundary | No Azure resource is created by this plan. Repository and credential-free document/code checks are designed to be cost-free. Later Azure plans/applies and deployed services may incur charges. |
| Authority to deploy | None is granted by this document. A separately approved change and authorized subscription are required. |
| Required companion | Complete every applicable row in [environment inputs](environment-inputs.md) and [the deployment runbook](production-deployment-runbook.md). |

## 1. Outcomes and exclusions

### Required outcomes

- A workload-measured and cost-reviewed Azure SQL pool design with named service and database owners.
- A private-only SQL access path, Entra authentication, approved identity/RBAC, and governed secrets handling.
- A secured remote Terraform state backend, reproducible provider lock file, protected source branch, and federated Azure DevOps identity.
- A reviewed plan artifact, server-side protected production approval, and a controlled apply of that exact plan.
- Measurable monitoring, tested alert routing, backup/restore evidence, and recovery procedures tied to approved RPO/RTO.
- An operations handover with ownership, dashboards, escalation paths, runbooks, and scheduled reviews.

### Explicit exclusions until separately designed and approved

- Selecting an actual subscription, tenant, region, SKU, pool size, budget, data classification, or production owner.
- Creating or changing any Azure resource, role assignment, Azure DevOps resource, DNS record, or network rule.
- Schema/data migration, application code changes, identity enrollment, data import, and production cutover.
- Grafana/Prometheus platform integration, exporter or scrape configuration, and dashboard implementation; track and approve this as a separate observability task.
- A claim that regional failover, restore, high availability, capacity, or service-level objectives have been tested.
- Secrets, personal information, credentials, subscription IDs, customer data, or production state in this Git repository.

The Terraform root is a starting implementation boundary, not proof that every organization policy or Azure feature requirement is met. Review it against current Microsoft documentation, current provider schemas, the landing zone, and security policies before any later deployment.

## 2. Decision principles

1. **No guessed production values.** Workload owners and platform owners fill in the companion worksheet with evidence and approvals.
2. **Fail closed.** Missing prerequisites, unexpected plan actions, unknown cost, network ambiguity, or an untested recovery objective stop the gate.
3. **Separate planning from execution.** Mermaid diagrams, Markdown, Terraform formatting, PDF generation, and source review do not deploy Azure resources. A Terraform `plan` requires real credentials and may access the Azure control plane; run it only after the plan gate.
4. **One owner per decision.** Each decision has a named accountable role, evidence, and approval record.
5. **Least privilege and protected execution.** Federated identity, scoped RBAC, server-side Azure DevOps branch controls, protected environment approvals, and exact-plan apply are mandatory.
6. **Test recoverability, not just configuration.** A configured retention value is not restore evidence; a DR diagram is not a failover test.
7. **Track ongoing cost and operational burden.** Estimate compute, storage, backups, monitoring ingestion/retention, network, DR capacity, and support before approval.

## 3. Delivery stages and gates

No stage assumes a calendar duration; the accountable owner schedules it after dependencies and change windows are known.

| Stage | Work and deliverables | Accountable owner | Exit gate |
| --- | --- | --- | --- |
| 0. Scope and service ownership | Service charter; supported use cases; application/database inventory; criticality; owners; data residency/classification; business hours and support model. | Service owner | Every database has a business and technical owner; scope and exclusions approved. |
| 1. Workload discovery | Peak and percentile CPU, data/log I/O, workers, sessions, storage, concurrency, latency, seasonality, batch/reporting peaks, growth and isolation needs. | DBA + application owners | Representative evidence covers normal, peak, burst, and growth scenarios; workload classes reviewed. |
| 2. Architecture and recovery decisions | Primary/secondary regions, topology, endpoint/DNS paths, SKU and feature selection, per-database limits, backup, RPO/RTO, failover/restore method, retention and compliance. | Platform architect + DBA + security | Architecture, recovery objectives, exceptions, and options analysis approved. |
| 3. Cost and capacity approval | SKU/region availability, quotas, capacity headroom, licensing eligibility, Azure pricing estimate, logging volume/retention, backup and DR cost, budget/alerts. | FinOps + capacity owner | Written estimate and quota evidence approved; budget owner accepts cost exposure. |
| 4. Landing-zone readiness | Subscription/tenant ownership, resource groups, policy/provider registration, network/subnet, private DNS, routes/NSGs, state account, private DNS, RBAC and monitoring workspace decisions. | Cloud platform + network | All IDs and access evidence collected; private resolution and private state path tested by the approved operators. |
| 5. Security and compliance review | Threat model, identity/data access, private access, encryption, auditing, Defender/Policy controls, least privilege, state/plan sensitivity, retention, incident contact. | Security + compliance | Controls mapped to requirements; risks and exceptions have owners and approvals. |
| 6. Delivery platform readiness | Repository protections, PR reviewers, CI, provider mirror or registry access, Linux agent, OIDC service connection, backend variables, protected environment, branch checks. | DevOps + cloud platform | No secrets in source; federation and branch/environment checks verified; nonproduction path works. |
| 7. Nonproduction implementation | Fill nonproduction values; commit provider lock file; offline validation; authenticated nonproduction plan and apply; app connection, monitoring, load, restore and runbook tests. | IaC owner + DBA + app owner | Change approved; tests pass; issues fixed; artifacts and evidence retained. |
| 8. Production readiness review | Complete inputs, cost, capacity, security, network, access, plan, operational and recovery evidence; freeze unrelated state changes. | Change manager | Go/no-go meeting records approver, window, rollback/stop decision owner, and exact reviewed artifact. |
| 9. Production deployment | Obtain a fresh production plan; verify target and plan; approve protected environment; apply only the exact approved plan; monitor changes. | Change manager + platform operator | Deployment matches expected actions; no unresolved warnings or unplanned replacement/deletion. |
| 10. Acceptance and handover | Smoke test through private DNS, Entra access, app health, pool/database metrics, audit/logs, alert delivery, inventory, cost, backup/restore and DR evidence. | Service owner + operations | Signed acceptance; on-call and escalation ownership active; open risks formally accepted. |
| 11. Operate and improve | Capacity/cost/security/alert review, patch/service health, access review, restore and failover drills, Terraform drift/change review, lifecycle updates. | Service owner + SRE/DBA | Scheduled cadence, evidence store, action owners, and re-approval triggers established. |

### Stop/go checklist

Do not pass a gate if any applicable item is unknown, unowned, or unsupported:

- [ ] Correct tenant, subscription, region, policies, quotas, and provider registrations are confirmed by the platform owner.
- [ ] Workload placement and capacity are based on evidence, not sample values or database count.
- [ ] SQL, VNet/subnet, Private DNS, state-storage, and agent network paths are identified and tested.
- [ ] Entra administrator and application identities are approved; permissions are scoped and reviewed.
- [ ] Cost estimate includes compute, storage, backup, diagnostics/Log Analytics, private networking, and recovery-region capacity.
- [ ] Backup, retention, restore, RPO/RTO, and regional recovery decisions are approved and testable.
- [ ] Terraform version/provider lock file, repository protection, state security, OIDC, branch check and environment approval are ready.
- [ ] The exact plan has no unapproved replacement, delete, public-access change, or permission escalation.
- [ ] Change window, communications, rollback/stop authority, on-call, and acceptance evidence owners are recorded.

## 4. Work breakdown and artifacts

| Workstream | Required repository or controlled-system artifacts | Evidence retained outside Git |
| --- | --- | --- |
| Product/service definition | Service inventory schema, ownership model, supported workload classes. | Approved inventory, service tier and change record. |
| Architecture | [`architecture.md`](architecture.md), [architecture diagram](../diagrams/production-architecture.mmd), [deployment flow](../diagrams/deployment-lifecycle.mmd), and [recovery flow](../diagrams/recovery-topology.mmd). | Network approval, regional feature support, threat model and decision record. |
| Environment configuration | Non-secret, reviewed environment configuration derived from [`environment-inputs.md`](environment-inputs.md). | Protected tfvars/variable group values and approval history; secrets only in approved secret store. |
| Infrastructure code | `terraform/production/*.tf`, reviewed module/provider versions, generated `.terraform.lock.hcl`, and code review. | Provider checksums, plan approval, CI results and Azure activity evidence. |
| Delivery | `azure-pipelines.yml`, `scripts/terraform-ado.sh`, protected branch, workload identity, restricted agent, gated environment. | Azure DevOps service connection, access review, branch checks, approvals and artifact permissions. |
| Operations/observability | Built-in Azure-native Log Analytics diagnostics, SQL auditing, six per-pool saturation alerts, action group, and Azure Monitor workbook; application telemetry contract and operating procedures. Grafana/Prometheus integration and dashboard setup are a separately scoped follow-up, not part of this delivery. | Ingestion freshness/category review, workbook query checks, alert routing test, on-call records, incident exercises and DBA/SRE threshold tuning. For the separate Grafana/Prometheus task, approve platform/source/security/cost design and verify data coverage, access, dashboards, alert routing, and support ownership. |
| Resilience | Approved recovery design and environment mapping. | Isolated restore test, failover exercise, measured data loss/RTO and corrective actions. |

## 5. Configuration and release workflow

1. Review this plan, the architecture, current Terraform scope, and the complete operator runbook.
2. Obtain the required named owners and fill the decision/evidence rows in [`environment-inputs.md`](environment-inputs.md). Leave unknown values as `TBD`; never turn a guess into a Terraform value.
3. Have each owning team verify IDs and permissions in the actual approved tenant/subscription through approved access channels. Do not paste credentials, secrets, or customer data into Git.
4. Establish shared services first: landing-zone policy and providers, VNet/subnet, private DNS, monitoring ownership, state storage/private endpoint, and state RBAC. Verify paths from the intended self-hosted deployment agent.
5. Protect `main`, require review, configure OIDC, restrict service-connection use to protected `refs/heads/main` with a server-side branch control check, and configure `sql-prod` approvals.
6. Create a nonproduction `.tfvars` in the approved protected configuration store. Review names, supported features, pool mapping, limits, backup settings, tags, and full cost estimate.
7. Run credential-free formatting/validation and repository checks. Provider initialization may need the approved registry/mirror. Review and commit the lock file in a controlled, connected environment.
8. Run nonproduction deployment from an approved runner. Review exact plan actions before apply. Execute application connectivity, load, permissions, monitoring, notification, restore and recovery tests.
9. Close defects and capture evidence. Have service, DBA, network, security, FinOps, operations, and change owners sign off the production gate.
10. At the approved change window, ensure no conflicting Terraform operations, create a fresh plan against the intended backend/workspace, inspect its target and all actions, and publish it with restricted retention/access.
11. Obtain environment approval for that plan. Apply the exact saved plan artifact. If source, inputs, state, or artifact changes, discard the approval and generate a fresh plan.
12. Complete acceptance/handover; retain change evidence in the organization-approved system, not in public logs or the source repository.

See the [lifecycle diagram](../diagrams/deployment-lifecycle.mmd) and the
[operator deployment procedure](production-deployment-runbook.md) for detailed
preparation and command steps.

## 6. Cost-free repository work vs. paid Azure deployment

| Activity | Azure resource charge expected? | Notes |
| --- | --- | --- |
| Edit/review Markdown, Mermaid source, Terraform, YAML, and scripts locally | No | Normal workstation and GitHub usage is outside Azure resource billing. |
| Render the PDF locally with Node.js | No | Uses local compute; no Azure API calls. |
| Terraform `fmt`, Bash syntax check, and static document checks | No | Local operations; no Azure resources. |
| Terraform `init -backend=false` | No Azure resource deployment | Downloads provider packages from the configured source; network or third-party registry terms may apply. |
| Terraform `validate` after initialization | No Azure resource deployment | Checks configuration against the downloaded provider schema. |
| Terraform `plan` with Azure credentials | No resources are intentionally created | It authenticates and queries Azure; it may incur non-resource operational/network costs and is not part of this credential-free package check. Do not run before the plan gate. |
| State backend bootstrap | Yes, if implemented | Storage, private endpoint, DNS/network, logs and backup may incur cost. Requires approved subscription and cost review. |
| SQL Terraform apply | Yes | SQL compute/storage, backups, monitoring ingestion/retention, private networking, and optional DR are billable. |
| GitHub Actions or Azure DevOps hosted/self-hosted runners | Depends on provider/organization plan and runner model | Review platform quotas/billing separately; Azure resource billing is distinct. |

No subscription is provided or assumed. No Azure login, plan, apply, state bootstrap, quota validation, or Azure resource creation is performed by this planning work.

## 7. Risk register

| Risk | Impact | Prevention / response | Owner |
| --- | --- | --- | --- |
| Example capacity is mistaken for workload sizing | Saturation, throttling, overspend or outage | Require measured profile, regional SKU/quota check, headroom and signed capacity review. | DBA + workload owner |
| Shared pool noisy-neighbor effects | Critical database degradation | Classify workload; isolate hot/regulated tenants; test burst and contention. | DBA |
| Private endpoint/DNS not reachable from app or runner | Application outage or failed plan/apply | Test name resolution and routes from each actual network; never bypass with public access. | Network |
| State identity or branch controls are too broad | Unauthorized infrastructure modification or state exposure | OIDC, least privilege, protected refs, server-side branch checks, restricted state and artifacts. | Security + DevOps |
| State loss/corruption or concurrent changes | Resource drift or unsafe changes | Blob leases, versioning/recovery controls, restricted access, state restoration procedure and change freeze. | IaC platform |
| Backup settings misread as tested recovery | Excessive data loss/downtime | Define RPO/RTO and run isolated restore and regional exercises with evidence. | Service owner + DBA |
| Diagnostic ingestion/retention cost is underestimated | Unexpected operational spend | Model volume and retention, alert on cost, review ingestion and destination policy. | FinOps + observability |
| Provider/service behavior changes | Failed plan or incompatible rollout | Pin CLI/provider, commit checksums, review release notes and retest in nonproduction. | IaC owner |
| Environment values remain placeholders or conflict | Wrong target, invalid deployment, production misconfiguration | Worksheet sign-off; validate subscription/tenant and resource IDs at plan; fail closed. | Release manager |
| Pipeline YAML modified by untrusted PR | Credential exposure or unauthorized deployment | Server-side service-connection branch checks and protected environments; YAML conditions alone are insufficient. | DevOps/security |

## 8. Change, rollback, and completion evidence

Infrastructure changes are not automatically reversible. A rollback may require a forward Terraform change, restoring data to a separate target, or an application-level recovery. Do not assume `terraform destroy` is safe or supported. Database resources use deletion protection in the current starter module; any exception must be explicit, backed up, separately approved, and reviewed for replacement/deletion effects.

For every production release retain, in the approved change system:

- Approved service inventory, design decisions, cost estimate, quota/SKU evidence, and owner approvals.
- Security, network, data classification, compliance, and identity/RBAC reviews.
- CI run, commit ID, Terraform/provider lock version, exact plan artifact identifier/checksum and approvals.
- Pre/post deployment health, app connectivity, SQL identity checks, alert delivery, diagnostics, and cost baseline.
- Restore/failover test results, measured RPO/RTO, data integrity checks, unresolved risks and owners.
- Final go/no-go, change communications, acceptance, and handover acknowledgements.

Completion means the acceptance and handover checklist in the [operations runbook](azure-sql-elastic-pool-operations-runbook.md) is satisfied, evidence owners have archived evidence, and all remaining risks have an approver and due date.

## 9. Review cadence and change triggers

Review this plan and environment worksheet at least annually and whenever any of these changes: region or subscription; data classification or residency; workload/ownership/capacity; RPO/RTO; SKU/provider version; network, DNS, identity, branch protection or service connection; retention or cost policy; Azure service feature support; or a failed restore, security incident, or material service incident. Revalidate links and Azure service limits against current Microsoft documentation.
