# Detailed Review Checklist

Load this reference when the proposal is complex or when a deeper review is requested.

## Business and ownership
- Problem statement and intended capability
- Business and technical owners
- Success criteria and operational dependencies
- Support, escalation, and incident ownership

## Architecture
- High-level and detailed data flows
- Trust boundaries and environment separation
- Internet-facing endpoints and network paths
- Downstream APIs, data stores, SaaS services, and third parties
- Administrative plane separated from workload execution

## Identity and access
- Human and workload identities
- Authentication protocol and credential lifecycle
- Permission scope, privileged actions, and role assignment authority
- Separation of duties
- Break-glass and emergency access
- Managed identity or workload federation feasibility

## Data protection
- Data classification, residency, encryption, retention, deletion, and backups
- Secrets and key management
- Tenant and customer isolation
- Log and cache content

## Detection and operations
- Security-relevant audit events
- Central log destination and retention
- Alerting, dashboards, and incident triggers
- Patch and upgrade cadence
- Change control and rollback
- Runbooks and service-level expectations

## Decision evidence
- Architecture diagrams
- Permission inventory
- Configuration or policy evidence
- Validation or test results
- Risk owner and exception approval
