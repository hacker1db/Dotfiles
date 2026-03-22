# Runbook — 10-Section Template

## Header Table

| Field | Value |
|-------|-------|
| **CR Number** | {cr_number} |
| **Change Date** | {change_date} |
| **Application** | {app_name} |
| **Tier** | {tier} |
| **Repository** | {repo_url} |
| **Team Email** | {team_email} |
| **Prepared By** | [PLACEHOLDER - engineer name] |
| **Approved By** | [PLACEHOLDER - approver name] |

## Section 1 — Change Description
Free text description + scope: components affected, environments, estimated duration.

## Section 2 — Risk Assessment
| Risk Factor | Assessment |
|-------------|------------|
| Dependency count | {count} direct |
| Blast radius | {assessment} |
| Data impact | {data stores} |
| User-facing | yes/no |
| Rollback complexity | low/medium/high |
| Overall risk | [PLACEHOLDER] |

List potential failure modes (container crash, failed migration, DNS delay, etc.)

## Section 3 — Prerequisites
Checklist: required approvals, dependent changes deployed, backups verified, feature flags configured, migration tested in staging.

## Section 4 — Implementation Steps
Table: Step | Action | Owner | Estimated Time. Derived from CI/CD stages. Expand each into sub-steps.

## Section 5 — Validation & Testing
Pre-implementation: unit/integration/e2e tests from pipeline.
Post-implementation: health check endpoints, monitoring checks, smoke tests, performance baseline.

## Section 6 — Rollback Plan
Auto-detect method from deploy type:
- Container: `kubectl rollout undo deployment/{app}`
- Git: `git revert <commit> && git push`
- Terraform: `terraform plan -target=<resource> && terraform apply`
- Helm: `helm rollback <release> <revision>`

Include trigger criteria (error rate, response time thresholds) and estimated rollback time.

## Section 7 — Systems & Dependencies
Tables for: directly affected systems, upstream dependencies, downstream dependencies, external integrations.

## Section 8 — Communication Plan
When | Who (team_email) | Channel | Message — cover pre-change, during, post-change, and rollback.

## Section 9 — Architecture Diagrams
Reference `docs/diagrams/` PNGs. Launch parallel `/drawio` agents for any missing diagrams. All are editable bitmap PNGs (drag into draw.io to edit):
- `{app_name}-conceptual.png` — service flow, blast radius
- `{app_name}-physical.png` — compute layers, cloud regions
- `{app_name}-network.png` — routing, load balancers, VNets
- `{app_name}-dataflow.png` — request lifecycle, persistence

After diagrams complete, embed via:
```markdown
![Conceptual](../diagrams/{app_name}-conceptual.png)
```

## Section 10 — Steps to Close
Checklist: validation checks passed, monitoring nominal, no elevated errors, stakeholder sign-off, ticket updated/closed, runbook archived, post-implementation review scheduled.

---

## Save & Publish

```
Docs/{app_name}-Runbook.md
Docs/{app_name}-Runbook.pdf   (via npx md-to-pdf --stylesheet ~/.dotfiles/claude/md-to-pdf.css)
```

ADO wiki publish:
```bash
az devops wiki page create \
  --org <org-url> --project <project> --wiki <wiki> \
  --path '<parent_path>/CR-{app_name}-{date}' \
  --content @/tmp/runbook-wiki.md --encoding utf-8
```
Use `update` with `--version <ETag>` if page exists.
