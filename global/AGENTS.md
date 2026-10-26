# Global Agent Policy

## File edits require a new worktree

- Before setting up the worktree, read and follow the `git-workflow` skill for Git operations, including Worktrunk (`wt`), branch naming, commits, and pull requests. Use the installed skill when available; otherwise read `~/Developer/skills/main/skills/git-workflow/SKILL.md` ([source](https://github.com/hacker1db/skills/blob/main/skills/git-workflow/SKILL.md)). If the skill or a required tool is unavailable, report it instead of silently substituting another workflow. The worktree requirement below still applies.
- Before editing files in a Git repository, always create a new worktree and a dedicated task branch. Never edit files in a checkout on `main`, `master`, or the repository's default branch, even for small changes, documentation, configuration, or generated files.
- Check the repository root, current branch, and working-tree status before any write. Create the worktree from the appropriate base, then use its absolute path as the working directory for all edits, formatting, code generation, and checks that write files.
- Create a new worktree for each new editing task. Continue using that task's worktree for follow-up work; changing branches in the original checkout is not a substitute.
- Resolve symlinks before writing. Never edit a main/default-branch checkout indirectly through a symlink or an installed configuration path; edit the source in the new worktree instead.
- Preserve existing changes in every other checkout. Do not reset, stash, move, or overwrite unrelated work to set up the worktree.
- If the required worktree cannot be created or accessed, stop before editing and report the blocker. Do not fall back to editing the main/default-branch checkout.

## User-facing plans

A user-facing plan is an implementation plan, project plan, investigation, migration, deployment plan, or other durable deliverable presented to the user as a plan artifact.

This policy applies when a user asks to create, save, update, find, review, open, complete, archive, or explicitly publish a user-facing plan.

Excluded:
- Transient reasoning or scratch thinking during a task
- Brief internal task lists that are not presented as deliverables
- Native planning mechanics and scratch state (`/plan`), which remain available; any durable plan or visualization finalized from native planning must follow the central-library finalization guard

## Central plan library

For every in-scope plan:

1. Use `~/notes/SecondBrain/4.Resources/plans` as the canonical library. Do not create tool-specific copies.
2. Delegate all operations to the `plan` executable in non-interactive JSON mode (`--json`).
3. Before opening or reviewing a plan, run `plan serve` and `plan doctor --json`. Report failures without inventing a dashboard URL.
4. After a successful plan mutation, run `plan push <id> --json` only when the user explicitly requests publishing or hosted synchronization.
5. Return the plan ID in all cases; return a hosted URL only when a successful explicit push confirms it on the configured site (`https://planmanager.hacker1db.dev`). Do not invent hosted URLs.
6. If the push fails, preserve the canonical local plan, report its absolute path and the push failure, and do not invent a hosted URL or substitute a localhost URL.
7. Before the final response, verify that every durable plan artifact has a successful plan-manager JSON result. Capture Markdown or HTML artifacts with `plan capture <artifact> --json` if needed, and report the artifact path and failure if capture fails.

## Adapter

Use the tool's plan adapter: Codex uses `$plans`; OpenCode and Copilot use `/plans`. Delegate operations to the `plan` CLI rather than reimplementing its storage or service behavior.

## Plan-manager source code

Keep the plan-manager repository in `~/Developer/plan-manager`, alongside other code repositories. For the bare-repository layout, use its `main/` worktree. The plan library remains `~/notes/SecondBrain/4.Resources/plans`.

## Workspace access

The plan library at `~/notes/SecondBrain/4.Resources/plans` is configured as a writable root in `~/.codex/config.toml`. If a managed application or organization policy prevents access, request approval when prompted and do not attempt to bypass the sandbox.

## Model

Do not change the model setting for plan operations.

## Native planning

Native `/plan` features remain available. Before returning a durable plan or visualization created through native planning, persist or capture it through the central CLI.

## Pull requests and issues

For every pull request:

1. Search the target repository for an existing GitHub issue that matches the work.
2. Reuse that issue, or create one before opening the pull request when no suitable issue exists.
3. Reference the issue in the pull request body. Use `Closes #<number>`, `Fixes #<number>`, or `Resolves #<number>` when the pull request fully completes the issue; use `Refs #<number>` and state the remaining work when it is only partial.
4. Verify the final pull request body contains the issue reference. Never create an unlinked pull request.

## Bug fixes and response status

When fixing a bug, find and fix the root cause, then verify with relevant checks. End the response with one short line stating what changed and a status light:

- 🟢 Green = verified working
- 🟡 Yellow = should work, but untested
- 🔴 Red = guessed or stuck

Never use green without naming what you ran to prove it.
