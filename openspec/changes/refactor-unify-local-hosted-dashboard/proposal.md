## Why

The local dashboard served by the plan-manager root package and the authenticated hosted site currently use separate frontends. This lets their navigation, rendering, refresh behavior, and styling drift even though they are views of the same plan library. The existing `src/dashboard` UI should be the canonical dashboard for both environments.

## What Changes

- Make `src/dashboard` the only source for the plan-manager browser UI, including library and plan-detail pages, styles, and client behavior.
- Move the hosted Next.js application into the root package's `src/app` structure and remove the separate `hosted/` application/package boundary.
- Keep `src/dashboard` as the only source for dashboard shells, styles, and client behavior; hosted-only pages/components adapt that source rather than duplicating it.
- Keep environment-specific behavior behind the existing local and hosted API boundaries: local files and loopback protections locally; authenticated hosted storage and authorization on Vercel.
- Define and test a shared API contract so the same dashboard client works against both backends without weakening hosted authentication or local protections.
- Update root development/build/test configuration and Vercel project setup so local development and hosted deployment use this same repository package and `src/` application source.
- Remove the duplicate hosted UI only after parity tests pass; retain hosted-only API routes, auth, persistence, and deployment configuration.

## Impact

- Affected capability: plan management dashboard and hosted plan viewing.
- Application repository: `~/Developer/sites/plan-manager` (the active checkout is `~/Developer/sites/plan-manager/main`).
- Main source: `src/dashboard/`, `src/app/`, `src/hosted/`, `src/server/`, root package/build scripts, and hosted API tests.
- Compatibility: local dashboard URL and hosted plan URLs remain stable; CLI commands, plan IDs, storage, and authentication remain unchanged.
- Deployment: Vercel deploys from the repository root; the separate `hosted/` app directory is removed while authenticated hosted APIs and storage remain.
