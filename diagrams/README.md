# Architecture and delivery diagrams

These Mermaid source files are reviewable design artifacts. They describe a
target design and are not evidence that Azure resources exist or that the
architecture has been approved.

| Diagram | File | Purpose |
| --- | --- | --- |
| Production architecture | [production-architecture.mmd](production-architecture.mmd) | Workload, private network, control plane, monitoring, and regional recovery boundaries. |
| Deployment lifecycle | [deployment-lifecycle.mmd](deployment-lifecycle.mmd) | Change review, identity, validation, plan artifact, approval, apply, and acceptance gates. |
| Recovery topology | [recovery-topology.mmd](recovery-topology.mmd) | Backup/restore and regional recovery decision flow. |
| Historical platform sketch | [azure-sql-elastic-pool-platform.mmd](azure-sql-elastic-pool-platform.mmd) | Earlier fleet-scale concept; not the deployment module scope. |

The architecture document explains ownership and exclusions. The production
readiness plan defines gate owners and evidence. Validate all product features,
regional support, network patterns, and recovery behavior against current
Microsoft documentation before implementation.
