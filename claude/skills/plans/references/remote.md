# Plan Remote Publishing Reference

## Overview

Hosted publishing is **opt-in and explicit**. The local `~/Developer/plans` library is always authoritative. A plan is never uploaded merely because it was created or updated.

Invoke `plan push` only after an explicit publish request from the user or a previously configured user policy.

Hosted publishing is an optional follow-on capability and is not enabled in the local-only v0.1 release. Until a hosted backend and remote CLI implementation are installed, `plan remote`, `plan auth`, and `plan push` exit with the dependency-unavailable code without changing local Markdown.

## Setup

```
plan remote add <name> <url>   # register a hosted plan service
plan auth login --remote <name>  # store credential in macOS Keychain
```

Credentials are revocable scoped application tokens stored in the OS Keychain. The CLI never receives Vercel, database, Blob, or deployment credentials.

## Publishing a plan

```
plan push <id-or-slug> [--remote <name>] --json
```

The response envelope adds `"hostedUrl"` and `"hostedRevision"`:
```json
{
  "version": 1,
  "id": "<stable-nanoid>",
  "path": "<absolute-path>",
  "url": "http://plans.localhost:4173/plans/<id>",
  "hostedUrl": "https://<configured-host>/plans/<id>",
  "hostedRevision": "<integer>",
  "contentHash": "<sha256>"
}
```

Return **both** `url` (local) and `hostedUrl` to the user after a successful push.

## Conflict handling

The CLI sends the previous hosted revision with each push. If the remote revision has advanced:
- Exit code 3 (stale hosted revision conflict)
- The hosted copy is not modified
- Local Markdown is not modified
- Fetch current remote state with `plan remote status <id> --json` and prompt the user to resolve

## Hosted service failures

Network, authentication, application, database, or object-storage failures:
- Exit non-zero with a descriptive error on stderr
- Do not modify local Markdown
- Do not claim the hosted copy was updated
- The local dashboard remains available at `url`

## Privacy

Published Markdown is stored as an immutable private object. The authorized download route returns `text/markdown`. The public Blob URL is never exposed. The hosted dashboard renders sanitized Markdown under a strict Content Security Policy.

## Bulk publishing

```
plan push --all [--remote <name>] --json
```

Plans are processed independently. Partial success is reported per-plan. A failure on one plan does not block others but the overall exit code is non-zero.

## Removing a remote

```
plan auth logout --remote <name>   # revoke and remove credential
plan remote list --json             # confirm removal
```

Removing a remote or logging out does not delete or change local Markdown files or the local dashboard.

## No per-plan deployment

Publishing a plan sends data to the hosted application's API. It does not run `vercel deploy`, create a Vercel project, or generate a static site per plan.
