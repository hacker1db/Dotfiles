# Change Request — 10-Section Output Template

## Header Table

| Field | Value |
|-------|-------|
| **CR Number** | {cr_number} |
| **Change Date** | {change_date} |
| **Change Window** | {change_window} |
| **Application** | {app_name} |
| **Type** | {standard\|emergency\|normal} |
| **Risk** | {low\|medium\|high\|critical} |
| **Environment** | {env} |
| **Repository** | {repo_url} |
| **Runbook** | {runbook_path_or_url} |
| **Team Email** | {team_email} |
| **Prepared By** | [PLACEHOLDER - engineer name] |
| **Approved By** | [PLACEHOLDER - approver name] |

## Section 1 — Change Description
Free-text description of the change + scope table (components affected, environments, estimated duration).

## Section 2 — Risk Assessment
Risk factor table: dependency count, blast radius, data impact, user-facing, rollback complexity, overall risk.
List potential failure modes based on infrastructure type.

## Section 3 — Prerequisites
Checklist: approvals, dependent changes deployed, backups verified. Auto-populate from CI/CD analysis.

## Section 4 — Implementation Steps
Table of steps derived from CI/CD pipeline stages: step, action, owner, estimated time. Expand each stage into sub-steps.

## Section 5 — Validation & Testing
Pre-implementation checks (unit, integration, e2e tests from pipeline). Post-implementation: health check endpoints, monitoring checks, smoke tests, perf baseline.

## Section 6 — Rollback Plan
Auto-detect rollback method from deploy type:
- Container: `kubectl rollout undo deployment/{app}`
- Git: `git revert <commit> && git push`
- Terraform: `terraform plan -target=<resource> && terraform apply`
- Helm: `helm rollback <release> <revision>`

Include rollback trigger criteria (error rate %, response time threshold) and estimated rollback duration.

## Section 7 — Systems & Dependencies
Tables for: directly affected systems, upstream dependencies, downstream dependencies, external integrations.

## Section 8 — Communication Plan
Table: when, who (team_email), channel, message. Cover: pre-change, during, post-change, rollback scenarios.

## Section 9 — Architecture Diagrams
Reference existing `docs/diagrams/` PNGs. Generate missing ones via `/drawio`. All are editable bitmap PNGs (embedded XML, drag into draw.io to edit).

## Section 10 — Steps to Close
Checklist: all validation checks passed, monitoring nominal, no elevated errors, stakeholder sign-off, ticket updated/closed, runbook archived, post-implementation review scheduled.

---

## Save & Publish

```
~/Downloads/CR-{cr_number}-{app_name}/
  CR-{cr_number}-{app_name}.md
  CR-{cr_number}-{app_name}.pdf    (via npx md-to-pdf)
```

Publish to ADO wiki via:
```bash
az devops wiki page create \
  --org <org-url> --project <project> --wiki <wiki> \
  --path '<parent_path>/CR-{app_name}-{date}' \
  --content @/tmp/cr-wiki.md --encoding utf-8
```
Use `update` with `--version <ETag>` if the page already exists.
