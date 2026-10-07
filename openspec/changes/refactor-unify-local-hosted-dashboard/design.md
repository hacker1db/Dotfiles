## Context

The root package runs a TypeScript CLI and loopback HTTP server. That server serves the dashboard from `src/dashboard` and accesses canonical Markdown files on disk. The hosted Next.js app currently lives in a separate `hosted/` package and duplicates runtime/build configuration. The requested architecture puts the hosted App Router under `src/app`, hosted adapters under `src/hosted`, and Next.js dependencies/scripts in the root package. Both the local server and Vercel then build from one repository package while keeping distinct backend trust boundaries.

## Goals / Non-Goals

- Goals: one repository package and one `src/` application source tree; one tracked browser UI source; equivalent layout, navigation, Markdown rendering, and refresh behavior locally and on Vercel; environment-appropriate data and security boundaries; reproducible local and hosted builds.
- Non-Goals: replacing local filesystem storage, moving local plans to the cloud, changing CLI behavior or URLs, removing hosted authentication, or making hosted plans public.

## Decisions

- Decision: `src/dashboard/` is the canonical frontend source. The hosted app consumes or packages these assets during its build; it must not keep independent library/detail page components or a separately maintained dashboard stylesheet.
- Decision: place Next.js routes in `src/app`, shared and hosted React adapters in `src/components`, and hosted-only auth/storage/database/migration code in `src/hosted`. Keep the existing root CLI and loopback HTTP server in `src/cli` and `src/server` as the local backend.
- Decision: retain two backend adapters. The local HTTP server continues to serve the dashboard and its existing local API. Root-package Next.js continues to enforce Clerk authorization and use hosted storage through route handlers. Both implement the same documented request/response contract expected by the shared dashboard client.
- Decision: preserve the stable local and hosted URL shapes. The dashboard client derives links from its current origin and uses the same library and plan route patterns in both environments.
- Decision: do not let a frontend-sharing refactor bypass server-side authorization, CSRF/origin checks, content sanitization, or hosted private-download controls. Tests must cover the shared client against both environments and verify hosted anonymous requests remain rejected.
- Decision: preserve root `pnpm run dev` as the local loopback dashboard workflow, and add a root `pnpm run dev:web` command for the same Next.js app that Vercel builds from the repository root. The root production build runs both the CLI build and Next.js build; root typecheck and tests cover both surfaces.
- Decision: Vercel's project root is the repository root, not a `hosted/` subdirectory. Move the local Vercel link metadata to the root without changing the project ID, and preserve local environment files without committing them.
- Alternatives considered: leaving the Next app in `hosted/` while syncing dashboard assets still leaves two app/package roots and contradicts the requested `src` consolidation. Moving all local filesystem behavior into Next.js would require a significant security/runtime rewrite. Instead, use one package and source tree with separate local and hosted backends.

## Risks / Trade-offs

- The current vanilla dashboard and hosted React pages may have behavior that is not yet represented by the shared client contract. Inventory and parity tests must precede removal of hosted pages.
- A client written for the local API could assume filesystem-specific fields or actions. Define capability differences explicitly; hide unsupported controls rather than silently breaking one environment.
- Sharing UI does not mean the backends are identical. Keep their trust boundaries and storage behavior separate and test each API implementation independently.
- Build-time copying can reintroduce drift if generated output is committed or Vercel builds from stale assets. Generate from tracked `src/dashboard` at build time and test source-to-build synchronization.

## Migration Plan

1. Inventory local and hosted routes, controls, data shapes, rendering, refresh, security behavior, Vercel project-root settings, and local ignored configuration that must be preserved.
2. Define the common dashboard API contract and document intentional environment capabilities.
3. Move hosted Next.js routes into `src/app`, hosted-specific code into `src/hosted`, shared components into `src/components`, and hosted tests/configuration into root-level conventional locations.
4. Merge dependency manifests and lockfiles into the root pnpm package; retain the local `pnpm dev` workflow and provide a separate Next.js dev command.
5. Add parity, security, and build tests; compare both surfaces and confirm no maintained app source or package remains under `hosted/`.
6. Update Vercel's project root to the repository root, deploy a preview, and verify authenticated library/detail flows and stable URLs before production promotion.
7. Roll back through Vercel deployment history; do not migrate or modify plan data as part of rollback.

## Open Questions

- Which dashboard actions should be offered on the hosted view if they are currently local-only (for example, open-in-editor, copy local path, status changes, or archive)? Preserve current behavior per environment unless the owner approves hosted mutations.
- Should any hosted-only metadata or controls be surfaced in the shared UI, or remain outside the initial parity scope?
