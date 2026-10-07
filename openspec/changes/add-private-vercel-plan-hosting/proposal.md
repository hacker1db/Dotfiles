## Why

The local plan manager is private because it runs only on loopback. A Vercel deployment needs an explicit authorization boundary before any plan content, metadata, upload API, or private object can be exposed beyond the machine.

The initial hosted service has one owner only. It must reject every request unless it is authorized as that owner or presents a separately scoped CLI credential.

## What Changes

- Add a separate Next.js hosted application under the plan-manager repository's `hosted/` directory.
- Use Clerk browser sessions and a required single owner Clerk user ID; no hosted sign-up route is provided.
- Protect every rendered page and browser API request with owner authorization; missing Clerk or owner configuration fails closed.
- Add a versioned upload API using revocable plan-manager CLI credentials, not Vercel, Blob, database, or deployment-protection credentials.
- Persist uploaded Markdown only in private object storage, and serve it only after server-side authorization and sanitization.
- Add an owner-only favicon and hosted metadata to the application.
- Document Vercel Deployment Protection as optional defense in depth, including its separate automation-bypass secret requirement.

## Impact

- Affected specification: `plan-management`
- Affected repository: `~/Developer/sites/plan-manager/main`
- New dependencies: Next.js, React, Clerk, Vercel Blob, and Neon Postgres client packages
- New required hosted configuration: Clerk keys, a single immutable owner user ID, private storage/database bindings, and hashed CLI token records
- No local plan, local dashboard, or dotfiles installer behavior changes until a hosted remote is explicitly configured
