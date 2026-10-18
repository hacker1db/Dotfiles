---
name: plan-manager
description: Manage durable implementation plans through the user's Plan Manager. Use when creating, revising, resuming, completing, publishing, or locating a non-trivial plan. Prefer the hosted Plan Manager for every plan mutation, with the Obsidian plan library as the automatic local fallback; do not use for one-step answers or ordinary task lists.
---

# Plan Manager

Treat the user's hosted Plan Manager as the preferred home for durable plans. The canonical local Markdown copy remains in the Obsidian vault, so a failed or unavailable remote never loses a plan. Chat summaries, scratchpads, and harness-specific plan modes are working views only.

## When to use it

Use this skill for a request that needs investigation, has several implementation steps, spans sessions or agents, or would benefit from an explicit decision record. Do not create a plan merely for a simple answer, a one-file mechanical edit, or when the user explicitly asks not to plan.

When a harness enters its native planning mode through `/plan`, invoke this skill immediately. Native plan mode determines how the harness reasons; Plan Manager remains the durable record and lifecycle authority.

Before creating a new plan, inspect the configured Plan Manager and search for an active plan with the same goal. Resume and update the existing plan when it is the same body of work; create a separate plan only when the goal or ownership is materially distinct. Never silently overwrite another plan.

## Hosted-first delivery

Create and update the local Markdown plan with the `plan` CLI in non-interactive JSON mode. This stores the durable fallback at `4.Resources/plans/` in the user's Obsidian vault before any remote operation.

After every successful plan mutation, immediately run `plan push <id> --json`. The user has authorized this automatic push to the configured hosted Plan Manager. Do not ask again before pushing ordinary plan mutations.

1. If the push succeeds, report the plan ID and the hosted URL returned by `plan push`. Prefer the hosted URL in all user-facing references.
2. If the push cannot complete, including because the user is signed out, the network is unavailable, the service rejects the request, or a revision conflict occurs, preserve the local plan. Report the plan ID, its absolute vault path, and a concise failure reason. Do not provide or prefer a `plans.localhost` URL as a substitute.
3. Do not run `plan auth login` or alter remote configuration unless the user specifically asks to authenticate or reconfigure the hosted service. A signed-out state is a normal fallback condition.
4. Do not delete, revert, or mark the local plan failed merely because its remote push failed.

Use `https://planmanager.hacker1db.dev` only through the configured `plan` CLI remote. Do not construct or claim a hosted plan URL unless the push result confirms it.

## Plan lifecycle

1. **Discover**: inspect the relevant code, documents, constraints, and existing plans before writing recommendations. Separate verified facts from assumptions and open questions.
2. **Draft**: create or revise the canonical Markdown plan. Make it specific enough that a different agent can execute it without rediscovering the reasoning.
3. **Sync**: push the successful local mutation to the hosted Plan Manager, following Hosted-first delivery.
4. **Review**: present the consequential choices, risks, and unanswered questions to the user. Planning is not approval to implement, make external changes, or close work.
5. **Execute**: as work proceeds, update the same plan with completed work, changed decisions, blockers, and validation evidence. Keep tasks small, observable, and in dependency order.
6. **Close**: mark the plan complete only after the requested outcome and stated validation are actually done. Preserve the implementation record; archive only at the user's request or under an established retention policy.

## Canonical plan shape

Use this structure unless the project supplies a required template. Omit empty sections rather than inventing details.

```markdown
# <concise outcome-oriented title>

## Goal
<the user outcome and success criteria>

## Context
<verified current state, relevant links or paths, and constraints>

## Scope
- In: ...
- Out: ...

## Decisions
- <decision>: <reasoning and trade-off>

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
- YYYY-MM-DD: <material update, evidence, or changed decision>
```

Use checkboxes only for executable tasks. Keep acceptance criteria and validation evidence concrete: a command and result, observed behavior, reviewer sign-off, or user confirmation. Link source files, issues, pull requests, and related plans where the target system supports links.

## Writing standards

- Lead with the user outcome, not the tools or agents involved.
- State facts with their source; label inferences, assumptions, and proposals clearly.
- Describe files, interfaces, migrations, compatibility, security, rollout, and rollback only when relevant to the request.
- Prefer decision-ready alternatives with trade-offs over a long menu of vague possibilities.
- Record a decision once it is made, including why; do not repeatedly reopen it without new evidence.
- Never place credentials, access tokens, private keys, or sensitive personal data in a plan.
- Respect repository-specific planning processes, templates, and approval gates. When those conflict with this format, use their required format and retain the same lifecycle principles.

## Handoff and resumption

At the end of a planning or execution turn, make the canonical plan the handoff source of truth. Report its title or location, current status, what changed, the next actionable item, any blocker, and either the verified hosted URL or the local vault path. A later agent must read that plan before continuing and update it instead of creating a parallel, stale version.
