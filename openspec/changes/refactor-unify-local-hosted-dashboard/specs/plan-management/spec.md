## MODIFIED Requirements

### Requirement: Canonical Dashboard Across Environments

The system SHALL maintain one canonical dashboard UI in the plan-manager repository's `src/dashboard/` source and SHALL serve that UI from both the local dashboard and authenticated hosted site. Environment-specific storage, APIs, and authorization MAY differ, but the visible navigation, layout, plan rendering, and refresh behavior SHALL remain aligned.

#### Scenario: Local development uses canonical dashboard

- **WHEN** a developer runs the root `pnpm run dev` command
- **THEN** the local server serves the UI from `src/dashboard/` at `http://plans.localhost:4173/`

#### Scenario: Hosted site packages canonical dashboard

- **WHEN** the hosted application is built for Vercel
- **THEN** it packages and serves the tracked `src/dashboard/` UI rather than a separately maintained dashboard page implementation

#### Scenario: Environment-specific API adapters

- **WHEN** the shared dashboard requests plan data in either environment
- **THEN** the environment's backend returns the shared typed dashboard contract while preserving local filesystem behavior or hosted authentication and storage boundaries, as appropriate

#### Scenario: Stable routes and refresh behavior

- **WHEN** an existing plan is updated while its detail view is open locally or on the hosted site
- **THEN** the shared dashboard refreshes the current plan at the same route without changing its stable URL

#### Scenario: Hosted access remains private

- **WHEN** an unauthenticated request attempts to load hosted plan content or call a protected hosted API
- **THEN** the hosted service rejects the request and does not reveal plan content, regardless of the shared dashboard assets

#### Scenario: Shared source changes

- **WHEN** dashboard UI source changes under `src/dashboard/`
- **THEN** the local development workflow and the next hosted build use that source without a separate manual UI rewrite or stylesheet copy
