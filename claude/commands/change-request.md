---
description: Generate a formal Change Request (CR) document by analyzing the current repository and auto-populating risk, scope, affected systems, and approval fields. Use this skill when the user wants to create a change request, CR, RFC, change ticket, change advisory board submission, or any formal change approval document. Also triggers on "create CR", "draft change request", "write up a CR", "change management doc", or "CAB submission".
---

# Change Request Generator

Generate a formal Change Request document by analyzing the current repository and auto-populating as many fields as possible from code, infrastructure, and CI/CD configuration.

## Argument Parsing

Parse `$ARGUMENTS` for:
- **Free text** — description of the change (everything not matched by a flag)
- `--cr <NUMBER>` — CR number (**required** — prompt if not provided)
- `--date <YYYY-MM-DD>` — planned implementation date (default: today)
- `--window <HH:MM-HH:MM>` — maintenance window start/end time (default: `[PLACEHOLDER - e.g. 22:00-23:00]`)
- `--type <standard|normal|emergency>` — change type (default: `normal`)
- `--risk <low|medium|high|critical>` — override auto-assessed risk level
- `--env <production|staging|dev>` — target environment (default: `production`)
- `--runbook <PATH>` — path to an existing runbook file to embed/link in the CR

**Before proceeding**, ask the user for any missing required inputs in a single prompt:
- If no `--cr` number was provided, ask for the CR number
- If no free-text description was provided, ask for the change description
- If no `--runbook` was provided, ask: "Do you have an existing runbook for this application? If so, provide the path (or press Enter to skip)."

## Step 0 — Fetch CR Template

Before analyzing the repository, fetch the official Change Request template from the ADO wiki to use as the authoritative structure for the output document.

Check memory for ADO wiki coordinates (org, project, wiki identifier, template page path). If found, use them. If not found, ask the user:

> I need to fetch your Change Request template from Azure DevOps wiki.
> Please provide the **organization**, **project**, **wiki identifier**, and **template page path**.

Then call `mcp__azure-devops__wiki_get_page_content` with those values. Parse the returned content — identify all required sections, fields, tables, and placeholders. This becomes the authoritative output structure. Keep the default template in Step 3 as a fallback for any sections not covered by the wiki template.

If the fetch fails, warn the user and proceed with the built-in template from Step 3.

## Step 1 — Repository Analysis

Scan the repository to understand the system being changed. Skip missing files gracefully — never error on absent sources.

**App identity** — scan for:
- `README.md`, `package.json`, `pom.xml`, `*.csproj`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `setup.py`
- Extract: app name, language, framework, version

**Infrastructure footprint** — scan for:
- `terraform/*.tf`, `bicep/*.bicep`, ARM templates, `Dockerfile`, `docker-compose.yml`, `containerapp.yaml`
- Identify: compute type, cloud provider, regions, resource types

**CI/CD pipeline** — scan for:
- `.github/workflows/*.yml`, `azure-pipelines.yml`, `.azure-pipelines/`, `Jenkinsfile`
- Extract: pipeline stages, deployment targets, environments

**Data stores** — scan for connection strings (names only, never values), ORM models, migration files, cache configs

**External integrations** — scan for API clients, webhook configs, third-party SDK imports

**Observability** — scan for Application Insights, Datadog, Prometheus, OpenTelemetry, Splunk config references

Build an internal summary:
- App name, language/framework, version
- Infrastructure components and cloud provider
- Data stores and their types
- External service dependencies
- Deployment method (rolling, blue/green, canary, in-place)
- Environments and promotion path

## Step 2 — Risk Assessment Logic

Compute an auto-assessed risk level from the repository summary:

| Factor | Low | Medium | High | Critical |
|--------|-----|--------|------|----------|
| Direct dependencies | <20 | 20–100 | 100–500 | 500+ |
| Data store changes | None | Read-only | Schema change | Destructive |
| User-facing surface | Internal only | Internal API | External API | Public + SLA |
| Rollback method | Redeploy | Git revert | DB restore | Manual only |
| Change type | Config | Code | Infrastructure | Multi-system |

Combine factors to produce an overall `low / medium / high / critical` assessment. If `--risk` was passed, use that value and note it overrides auto-assessment.

## Step 3 — Generate CR Document

Produce the full CR document. Auto-populate every field possible from Step 1. Use `[PLACEHOLDER - description]` for fields that cannot be determined from the repository.

```markdown
# Change Request

| Field | Value |
|-------|-------|
| **CR Number** | {cr_number} |
| **Change Type** | {type} |
| **Status** | Draft |
| **Requested By** | [PLACEHOLDER - requester name] |
| **Approved By** | [PLACEHOLDER - approver name / CAB] |
| **Application** | {app_name} |
| **Environment** | {env} |
| **Planned Date** | {date} |
| **Maintenance Window** | {window} |
| **Risk Level** | {risk_level} |
| **Repository** | {repo_url — auto-detect via `git remote get-url origin`} |

---

## 1. Summary

{free_text_description}

### Scope
- **What is changing:** {description of code, config, or infrastructure being modified}
- **Components affected:** {list from analysis}
- **Environments:** {environments from CI/CD analysis}
- **Not in scope:** [PLACEHOLDER - explicitly call out what is NOT changing]

---

## 2. Business Justification

[PLACEHOLDER - business reason for this change: bug fix, new feature, compliance requirement, performance improvement, etc.]

**Expected benefit:** [PLACEHOLDER - measurable outcome]
**Risk of not changing:** [PLACEHOLDER - impact if deferred]

---

## 3. Risk Assessment

| Factor | Detail | Rating |
|--------|--------|--------|
| **Change complexity** | {deployment method and scope} | {low/medium/high} |
| **Blast radius** | {systems and users affected} | {low/medium/high} |
| **Data impact** | {data stores affected, migration required?} | {low/medium/high} |
| **Dependency exposure** | {count} direct dependencies | {low/medium/high} |
| **Rollback complexity** | {auto-detected rollback method} | {low/medium/high} |
| **Overall risk** | | **{risk_level}** |

### Potential Failure Modes
{list 3–5 specific failure modes based on infrastructure type, e.g.:}
- Container fails to start due to bad environment variable
- Database migration times out under load
- Downstream service breaks due to API contract change
- DNS/load balancer propagation delay causes brief 5xx responses
- [PLACEHOLDER - additional failure modes]

### Mitigations
- [ ] {auto-populated: e.g., "Feature flag enabled — can be toggled without redeploy"}
- [ ] {auto-populated: e.g., "Blue/green deployment allows instant traffic cutover"}
- [ ] [PLACEHOLDER - additional mitigations]

---

## 4. Implementation Plan

High-level steps for executing the change. For detailed step-by-step procedures, see the accompanying runbook{runbook_link — if a runbook was provided, reference it here as a relative or absolute path link}.

**Runbook:** {runbook_path if provided, otherwise "[PLACEHOLDER - link to runbook]"}

{auto-populated skeleton from CI/CD pipeline stages}

| Step | Action | Owner | Est. Duration |
|------|--------|-------|---------------|
| 1 | Pre-change validation (smoke tests, dependency checks) | [PLACEHOLDER] | [PLACEHOLDER] |
| 2 | {first pipeline stage or deploy step from CI/CD analysis} | [PLACEHOLDER] | [PLACEHOLDER] |
| 3 | {next stage} | [PLACEHOLDER] | [PLACEHOLDER] |
| N | Post-change validation | [PLACEHOLDER] | [PLACEHOLDER] |

**Total estimated duration:** [PLACEHOLDER - sum of above]

---

## 5. Rollback Plan

**Trigger criteria — initiate rollback if:**
- Error rate exceeds [PLACEHOLDER - threshold]% within [PLACEHOLDER - window] minutes
- Health check fails for more than [PLACEHOLDER - N] consecutive checks
- [PLACEHOLDER - additional criteria]

**Rollback method:** {auto-detected based on deploy type}

{One of the following, based on detected infrastructure:}
- **Container/image revert:** `{rollback command}`
- **Git revert:** `git revert <commit> && git push` → pipeline redeploys previous version
- **Terraform rollback:** `terraform plan -target=<resource> && terraform apply`
- **Helm rollback:** `helm rollback <release> <revision>`
- **In-place revert:** [PLACEHOLDER - manual rollback procedure]

**Rollback owner:** [PLACEHOLDER - on-call engineer or team]
**Estimated rollback duration:** [PLACEHOLDER]

---

## 6. Affected Systems

### Directly Modified
| System | Type | Change |
|--------|------|--------|
| {app_name} | {compute type} | {description of change} |
| {data store if schema changes} | {database/cache/queue} | {migration or config change} |

### Upstream Dependencies
{services this application depends on — from external integrations analysis}

### Downstream Consumers
[PLACEHOLDER - services or teams that consume this application's API or data]

---

## 7. Testing & Validation

### Pre-Change (Required Before Window)
- [ ] {tests from CI/CD pipeline — unit, integration, e2e if detected}
- [ ] Staging environment validated
- [ ] [PLACEHOLDER - performance baseline captured]
- [ ] [PLACEHOLDER - load test run against staging]

### Post-Change (During Window)
- [ ] Health check endpoints responding: {list API health routes if found}
- [ ] {observability tool if detected} dashboards nominal
- [ ] No elevated error rates in {log aggregation tool if detected}
- [ ] [PLACEHOLDER - smoke test checklist]

### Success Criteria
[PLACEHOLDER - define what "done and healthy" looks like in measurable terms]

---

## 8. Communication Plan

| Timing | Audience | Channel | Message |
|--------|----------|---------|---------|
| 48h before | [PLACEHOLDER - stakeholders] | [PLACEHOLDER - email/Slack/Teams] | Change window notification |
| 15 min before | [PLACEHOLDER - on-call team] | [PLACEHOLDER - channel] | Starting change |
| During | [PLACEHOLDER - on-call team] | [PLACEHOLDER - channel] | Status updates |
| On completion | [PLACEHOLDER - stakeholders] | [PLACEHOLDER - channel] | Change complete, systems nominal |
| On rollback | [PLACEHOLDER - stakeholders + management] | [PLACEHOLDER - channel] | Rollback initiated, ETA to resolution |

---

## 9. Approvals

| Role | Name | Approved | Date |
|------|------|----------|------|
| Change Requestor | [PLACEHOLDER] | | |
| Technical Lead | [PLACEHOLDER] | | |
| Change Manager / CAB | [PLACEHOLDER] | | |
| [PLACEHOLDER - additional approver] | | | |

---

## 10. Post-Implementation Review

- [ ] All validation checks passed (Section 7)
- [ ] Metrics nominal for [PLACEHOLDER - stabilization period, e.g. 30 minutes]
- [ ] No rollback triggered
- [ ] [PLACEHOLDER - stakeholder sign-off received]
- [ ] Change ticket updated and closed
- [ ] Lessons learned documented: [PLACEHOLDER - any surprises or process improvements]
- [ ] Post-implementation review scheduled: [PLACEHOLDER - date, for high/critical risk changes]
```

## Step 4 — Save and Present

The output directory is `~/Downloads/CR-{cr_number}-{app_name}/`. All files go here — no repo commits, no docs/ subdirectory.

1. **Create the output directory:**
   ```bash
   mkdir -p ~/Downloads/CR-{cr_number}-{app_name}
   ```

2. **Save the markdown CR:**
   ```bash
   # Output file
   ~/Downloads/CR-{cr_number}-{app_name}/CR-{cr_number}-{app_name}-{date}.md
   ```

3. **Copy the runbook** — if a runbook path was provided, copy it alongside the CR:
   ```bash
   cp "{runbook_path}" ~/Downloads/CR-{cr_number}-{app_name}/runbook.md
   ```
   If no runbook was provided, skip this step and note it in the summary.

4. **Generate PDF** using `md-to-pdf` (https://www.npmjs.com/package/md-to-pdf):
   ```bash
   # Generate PDF (npx pulls md-to-pdf on demand, no global install needed)
   npx md-to-pdf ~/Downloads/CR-{cr_number}-{app_name}/CR-{cr_number}-{app_name}-{date}.md
   ```
   This produces `CR-{cr_number}-{app_name}-{date}.pdf` in the same directory.

5. **Publish to Azure DevOps Wiki** — check memory for ADO wiki coordinates (org, project, wiki identifier, parent page path for changes). If found, use them without asking. If not found, ask the user:

   > Please provide the **organization**, **project**, **wiki identifier**, and **parent page path** where change requests should be published.

   a. **Create the wiki page** using `mcp__azure-devops__wiki_create_or_update_page`:
      - `wikiIdentifier`: from memory or user input
      - `project`: from memory or user input
      - `path`: `{parent_path}/CR-{cr_number}-{app_name}-{date}`
      - `content`: the CR markdown content (same as the saved `.md` file)

   b. If the page already exists (version conflict), fetch the existing page's ETag and call update instead.

   c. Note the published wiki page path in the summary.

6. **Present a summary:**

```
## Change Request Generated

**CR Number:** {cr_number}
**Output:** ~/Downloads/CR-{cr_number}-{app_name}/
  ├── CR-{cr_number}-{app_name}-{date}.md
  ├── CR-{cr_number}-{app_name}-{date}.pdf
  └── runbook.md  (if provided)

**ADO Wiki:** {link to the created wiki page}
**Risk Level:** {risk_level} ({auto-assessed or overridden})

### Auto-populated fields:
- {list fields filled from repo analysis}

### Requires manual input:
- {list all [PLACEHOLDER] fields}

### Next steps:
- Fill in [PLACEHOLDER] fields
- Route for approvals per Section 9
- Run /runbook if you need a detailed step-by-step implementation runbook
```

$ARGUMENTS
