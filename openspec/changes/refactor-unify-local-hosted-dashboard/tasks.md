## 1. Inventory and contract

- [x] 1.1 Inventory local dashboard routes, controls, client requests, rendering and refresh behavior, plus hosted pages, API handlers, auth, and storage.
- [x] 1.2 Define a typed shared dashboard API contract for library listing/search, plan detail/revision refresh, and any supported mutations or downloads.
- [x] 1.3 Mark local-only and hosted-only actions explicitly; retain current per-environment behavior unless a product decision approves expanding it.

## 2. Shared dashboard source

- [x] 2.1 Refactor `src/dashboard/` to be the sole maintained source for the dashboard shell, library, plan detail, styling, Markdown display, and refresh client.
- [x] 2.2 Keep local dashboard behavior intact while adapting its API responses to the shared contract.
- [x] 2.3 Configure the hosted build to package and serve the canonical `src/dashboard/` assets for library and stable plan routes; remove duplicate hosted page and stylesheet implementations after parity is verified.
- [x] 2.4 Keep hosted auth, private data access, sanitization, downloads, and mutations enforced by hosted server-side route handlers.
- [x] 2.5 Move hosted Next.js routes and app configuration into the root package and `src/`; remove the separate `hosted/` source/package directory without losing local environment or Vercel link configuration.

## 3. Parity and security verification

- [x] 3.1 Add shared UI/API contract tests for library listing/search, detail rendering, status display, and revision refresh against local and hosted adapters.
- [x] 3.2 Verify an update refreshes the currently open plan at the same URL in both environments.
- [x] 3.3 Verify local loopback, Host/Origin/CSRF protections and hosted session auth, ownership checks, private downloads, and anonymous rejection remain intact.
- [x] 3.4 Verify Markdown sanitization produces equivalent safe output from the shared UI for raw HTML and unsafe URL inputs.
- [x] 3.5 Add a build check proving hosted assets are generated from `src/dashboard/` and no duplicate maintained dashboard UI remains.

## 4. Developer and deployment workflow

- [x] 4.1 Make root `pnpm run dev` serve the canonical dashboard source with fast refresh/reload during development.
- [x] 4.2 Update root and hosted typecheck, test, and build scripts to validate the shared UI and both API adapters.
- [x] 4.3 Update repository and deployment documentation to explain the single UI source and separate local/hosted backends.
- [ ] 4.4 Merge root and hosted package dependencies/lockfiles; preserve `pnpm dev` for the local dashboard and add root Next.js scripts for web development, typecheck, tests, and production build.
- [x] 4.5 Configure the existing Vercel project to build from the repository root, leaving its framework, build/install commands, domains, and integrations intact.
- [ ] 4.6 Deploy a preview, verify authenticated library/detail pages and stable URLs, then promote the verified deployment to production.
