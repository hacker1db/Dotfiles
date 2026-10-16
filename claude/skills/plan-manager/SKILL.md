---
name: plan-manager
description: Manage durable implementation plans through the user's Plan Manager. Use when creating, revising, resuming, or completing a non-trivial plan; do not use for one-step answers or ordinary task lists.
---

# Plan Manager

Treat the user's Plan Manager as the canonical home for durable plans. A plan is a Markdown document that survives the current chat and gives any later agent enough context to continue safely. Chat summaries, scratchpads, and harness-specific plan modes are working views only; keep the canonical plan current when this skill applies.

## When to use it

Use this skill for a request that needs investigation, has several implementation steps, spans sessions or agents, or would benefit from an explicit decision record. Do not create a plan merely for a simple answer, a one-file mechanical edit, or when the user explicitly asks not to plan.

When a harness enters its native planning mode through `/plan`, invoke this skill immediately. Native plan mode determines how the harness reasons; Plan Manager remains the durable record and lifecycle authority.

Before creating a new plan, inspect the configured Plan Manager and search for an active plan with the same goal. Resume and update the existing plan when it is the same body of work; create a separate plan only when the goal or ownership is materially distinct. Never silently overwrite another plan.

If Plan Manager is not configured or accessible, say so briefly and ask where the plan should live. Do not invent a remote, token, directory, or account, and do not configure one without authorization.

## Plan lifecycle

1. **Discover** — inspect the relevant code, documents, constraints, and existing plans before writing recommendations. Separate verified facts from assumptions and open questions.
2. **Draft** — create or revise the canonical Markdown plan. Make it specific enough that a different agent can execute it without rediscovering the reasoning.
3. **Review** — present the consequential choices, risks, and unanswered questions to the user. Planning is not approval to implement, make external changes, or close work.
4. **Execute** — as work proceeds, update the same plan with completed work, changed decisions, blockers, and validation evidence. Keep tasks small, observable, and in dependency order.
5. **Close** — mark the plan complete only after the requested outcome and stated validation are actually done. Preserve the implementation record; archive only at the user's request or under an established retention policy.

## Canonical plan shape

Use this structure unless the project supplies a required template. Omit empty sections rather than inventing details.

```markdown
# <concise outcome-oriented title>

## Goal
<the user outcome and success criteria>

## Context
<verified current state, relevant links/paths, and constraints>

## Scope
- In: ...
- Out: ...

## Decisions
- <decision> — <reasoning and trade-off>

## Open questions
- [ ] <question, owner, or condition for resolution>

## Plan
- [ ] <observable step and expected result>
- [ ] <dependent step>

## Validation
- <test, manual check, or acceptance signal>

## Risks and rollback
- <risk and mitigation or recovery path>

## Progress log
- YYYY-MM-DD — <material update, evidence, or changed decision>
```

Use checkboxes only for executable tasks. Keep acceptance criteria and validation evidence concrete: a command/result, observed behavior, reviewer sign-off, or user confirmation. Link source files, issues, pull requests, and related plans where the target system supports links.

## Writing standards

- Lead with the user outcome, not the tools or agents involved.
- State facts with their source; label inferences, assumptions, and proposals clearly.
- Describe files, interfaces, migrations, compatibility, security, rollout, and rollback only when relevant to the request.
- Prefer decision-ready alternatives with trade-offs over a long menu of vague possibilities.
- Record a decision once it is made, including why; do not repeatedly reopen it without new evidence.
- Never place credentials, access tokens, private keys, or sensitive personal data in a plan.
- Respect repository-specific planning processes, templates, and approval gates. When those conflict with this format, use their required format and retain the same lifecycle principles.

## Handoff and resumption

At the end of a planning or execution turn, make the canonical plan the handoff source of truth. Report its title or location, current status, what changed, the next actionable item, and any blocker. A later agent must read that plan before continuing and update it instead of creating a parallel, stale version.
