---
description: Generate a Change Request runbook by analyzing the current repository, then invoke /drawio to generate architecture diagrams
---
# Change Request Runbook Generator

Generate a comprehensive Change Request runbook by analyzing the current repository, auto-populating as many fields as possible, and invoking `/drawio` to produce architecture diagrams.

## Argument Parsing

Parse `$ARGUMENTS` for:
- **Free text** = description of the change (everything not matched by a flag)
- `--cr <NUMBER>` — optional CR number (default: `[PLACEHOLDER - CR number]`)
- `--date <YYYY-MM-DD>` — change date (default: today's date)
- `--tier <0|1|2|3>` — urgency tier (default: `[PLACEHOLDER - urgency tier 0-3]`)
- `--diagrams <conceptual,physical,network,dataflow>` — comma-separated list of diagrams to generate (default: all four)

If no free-text description is provided, ask the user once before proceeding.

## Step 1 — Repository Analysis

Scan the repository to build an internal summary. Skip any files or directories that do not exist — never error on missing sources.

**App identity** — scan for:
- `README.md`, `package.json`, `pom.xml`, `*.csproj`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `setup.py`
- Extract: app name, language, framework, version

**Dependencies** — scan for:
- `package.json` (npm), `pom.xml` (Maven), `*.csproj` (NuGet), `go.sum`, `Cargo.lock`, `requirements.txt`, `poetry.lock`
- Count direct and transitive dependencies

**Infrastructure** — scan for:
- `terraform/*.tf`, `bicep/*.bicep`, ARM templates (`*.json` with `$schema` containing `deploymentTemplate`)
- `Dockerfile`, `docker-compose.yml`, `docker-compose.yaml`, `containerapp.yaml`
- Identify: compute type, cloud provider, regions, resource types

**CI/CD** — scan for:
- `.github/workflows/*.yml`, `azure-pipelines.yml`, `.azure-pipelines/`, `Jenkinsfile`
- Extract: pipeline stages, deployment targets, environments

**Kubernetes** — scan for:
- `kubernetes/`, `helm/`, `charts/`, `k8s/`, `kustomization.yaml`
- Extract: services, deployments, ingress rules

**Config** — scan for:
- `appsettings*.json`, `.env.example`, `config/`, `*.config.js`, `*.config.ts`
- Identify: environment variables, feature flags, connection strings (names only, never values)

**Source structure** — scan for:
- `src/` top-level layout, API route definitions, data access patterns
- Identify: API endpoints, database access layers, external service calls

**Existing docs** — scan for:
- `docs/`, OpenAPI specs (`openapi.yaml`, `swagger.json`), `ARCHITECTURE.md`

Build an internal summary containing:
- App name, language/framework, version
- Dependency count (direct + transitive)
- Infrastructure components (compute, storage, networking)
- Data stores (databases, caches, queues)
- External integrations (third-party APIs, SaaS services)
- Network topology (VNets, subnets, load balancers, DNS)
- CI/CD stages and deployment method
- Observability tools (Application Insights, Datadog, Prometheus, etc.)

## Step 2 — Generate Runbook Markdown

Generate the runbook with **all 10 sections** below. Auto-populate from the Step 1 analysis wherever possible. Use `[PLACEHOLDER - description]` for any field that cannot be determined from the repository.

### Output Template

```markdown
# Change Request Runbook

| Field | Value |
|-------|-------|
| **CR Number** | {cr_number} |
| **Change Date** | {change_date} |
| **Application** | {app_name} |
| **Tier** | {tier} |
| **Prepared By** | [PLACEHOLDER - engineer name] |
| **Approved By** | [PLACEHOLDER - approver name] |

## 1. Change Description

{free_text_description}

### Scope
- **Components affected:** {list from analysis}
- **Environments:** {environments from CI/CD analysis}
- **Estimated duration:** [PLACEHOLDER - estimated duration]

## 2. Risk Assessment

| Risk Factor | Assessment |
|-------------|------------|
| **Dependency count** | {count} direct dependencies |
| **Blast radius** | {assessment based on infra type and connected systems} |
| **Data impact** | {data stores affected} |
| **User-facing** | {yes/no based on API/UI presence} |
| **Rollback complexity** | {low/medium/high based on deploy type} |
| **Overall risk** | [PLACEHOLDER - low/medium/high/critical] |

### Failure Modes
{list potential failure modes based on infrastructure type — e.g., container crash, failed migration, DNS propagation delay}

## 3. Prerequisites

- [ ] [PLACEHOLDER - required approvals obtained]
- [ ] [PLACEHOLDER - dependent changes deployed]
- [ ] Backups verified: [PLACEHOLDER - backup details]
- [ ] {auto-populated prerequisites from CI/CD analysis, e.g., "Feature flags configured", "Database migration tested in staging"}

## 4. Implementation Steps

{auto-populated skeleton from CI/CD pipeline stages}

| Step | Action | Owner | Estimated Time |
|------|--------|-------|----------------|
| 1 | {first pipeline stage or deploy step} | [PLACEHOLDER] | [PLACEHOLDER] |
| 2 | {next stage} | [PLACEHOLDER] | [PLACEHOLDER] |
| ... | ... | ... | ... |

### Detailed Steps
{expand each CI/CD stage into sub-steps where possible}

## 5. Validation & Testing

### Pre-Implementation
- [ ] {tests from CI/CD pipeline — unit, integration, e2e}
- [ ] [PLACEHOLDER - manual test cases]

### Post-Implementation
- [ ] Health check endpoints responding: {list API routes if found}
- [ ] {monitoring checks based on detected observability tools}
- [ ] [PLACEHOLDER - smoke test scenarios]
- [ ] [PLACEHOLDER - performance baseline comparison]

## 6. Rollback Plan

**Rollback method:** {auto-detected based on deploy type}
{One of:}
- Container revert: `{rollback command for container deployments}`
- Git revert: `git revert <commit> && git push`
- Terraform rollback: `terraform plan -target=<resource> && terraform apply`
- Helm rollback: `helm rollback <release> <revision>`
- [PLACEHOLDER - custom rollback procedure]

**Rollback trigger criteria:**
- [ ] Error rate exceeds [PLACEHOLDER - threshold]%
- [ ] Response time exceeds [PLACEHOLDER - threshold]ms
- [ ] [PLACEHOLDER - additional criteria]

**Rollback estimated time:** [PLACEHOLDER - estimated rollback duration]

## 7. Systems & Dependencies

### Directly Affected Systems
{table from dependency analysis}

| System | Type | Impact |
|--------|------|--------|
| {system} | {compute/database/cache/queue/external} | {description} |

### Upstream Dependencies
{services that this application depends on}

### Downstream Dependencies
{services that depend on this application}

### External Integrations
{third-party services, SaaS platforms}

## 8. Communication Plan

| When | Who | Channel | Message |
|------|-----|---------|---------|
| Pre-change | [PLACEHOLDER - stakeholders] | [PLACEHOLDER - channel] | Change window beginning |
| During | [PLACEHOLDER - on-call team] | [PLACEHOLDER - channel] | Status updates |
| Post-change | [PLACEHOLDER - stakeholders] | [PLACEHOLDER - channel] | Change complete |
| Rollback | [PLACEHOLDER - stakeholders] | [PLACEHOLDER - channel] | Rollback initiated |

## 9. Architecture Diagrams

{Reference existing editable PNG diagrams in docs/diagrams/. If diagrams already exist, embed them directly. Each PNG is an editable bitmap — drag into draw.io to modify.}

| Diagram | File | Description |
|---------|------|-------------|
| Conceptual | `docs/diagrams/{app_name}-conceptual.png` | Service flow, blast radius, component relationships |
| Physical | `docs/diagrams/{app_name}-physical.png` | Compute layers, cloud regions, Azure resources |
| Network | `docs/diagrams/{app_name}-network.png` | Routing, load balancers, firewalls, VNets |
| Data Flow | `docs/diagrams/{app_name}-dataflow.png` | Request lifecycle, transformations, persistence |

> **Note:** All diagrams are editable bitmap PNGs with embedded draw.io XML. Drag any PNG into draw.io to edit.

## 10. Steps to Close

- [ ] All validation checks passed (Section 5)
- [ ] {monitoring tool} dashboards show nominal metrics
- [ ] No elevated error rates in {log aggregation tool if detected}
- [ ] [PLACEHOLDER - stakeholder sign-off received]
- [ ] [PLACEHOLDER - change ticket updated and closed]
- [ ] Runbook archived to `docs/runbooks/`
- [ ] Post-implementation review scheduled: [PLACEHOLDER - date]
```

## Step 3 — Architecture Diagrams

After generating the runbook, check for existing diagrams in `docs/diagrams/` and generate any missing ones via `/drawio`. All diagrams are **editable bitmap PNGs** (no separate `.drawio` files needed — the XML is embedded in the PNG).

### 3a. Check for existing diagrams

Search `docs/diagrams/` for PNGs matching the app name. If a diagram already exists, reference it in the runbook — do not regenerate.

### 3b. Generate missing diagrams

For each missing diagram type requested (default: all four), invoke `/drawio` as a separate follow-up action. Each `/drawio` invocation produces a single editable PNG saved to `docs/diagrams/{app_name}-{type}.png`.

1. **Conceptual diagram** — invoke `/drawio` with:
   > Create a conceptual architecture diagram for {app_name}. Show the service flow including: {list components, their relationships, and the blast radius of this change}. Highlight components affected by this change. Save as `docs/diagrams/{app_name}-conceptual.png`.

2. **Physical diagram** — invoke `/drawio` with:
   > Create a physical architecture diagram for {app_name}. Show compute layers, cloud regions, and Azure resources: {list infrastructure components from Terraform/Bicep/ARM analysis}. Include resource types, SKUs where known, and region placement. Save as `docs/diagrams/{app_name}-physical.png`.

3. **Network diagram** — invoke `/drawio` with:
   > Create a network architecture diagram for {app_name}. Show routing, load balancers, firewalls, and VNets: {list network topology from infrastructure analysis}. Include traffic flow directions and ports. Save as `docs/diagrams/{app_name}-network.png`.

4. **Data flow diagram** — invoke `/drawio` with:
   > Create a data flow diagram for {app_name}. Show the request lifecycle from entry point through transformations to persistence: {list API routes, data stores, message queues, and external integrations}. Include data formats and protocols. Save as `docs/diagrams/{app_name}-dataflow.png`.

**Important:** If the repository lacks sufficient data for a diagram type (e.g., no Terraform files for the network diagram), generate the `/drawio` invocation anyway with placeholder descriptions and clearly mark unknown components as `[PLACEHOLDER - description]` in the diagram instruction.

**Output format:** Each diagram is an editable bitmap PNG only — no `.drawio` source file. The draw.io XML is embedded in the PNG via `--embed-diagram`, so users can drag the PNG into draw.io to edit.

## Step 4 — Save and Present

1. Create the `docs/runbooks/` directory if it does not exist
2. Save the runbook to: `docs/runbooks/CR-{app_name}-{change_date}.md`
3. Present a summary to the user:

```
## Runbook Generated

**File:** docs/runbooks/CR-{app_name}-{change_date}.md

### Auto-populated fields:
- {list sections/fields that were populated from repo analysis}

### Requires manual input:
- {list all [PLACEHOLDER] fields that need human input}

### Diagrams:
- {list existing diagrams found and any new /drawio invocations to be made}
- All diagrams are editable bitmap PNGs (drag into draw.io to edit)
```

4. Then proceed to invoke `/drawio` for each **missing** diagram type as described in Step 3.

$ARGUMENTS
