## MODIFIED Requirements

### Requirement: Central Local Dashboard

The system SHALL serve all managed plans from `http://plans.localhost:4173/`, SHALL bind the service only to loopback, and SHALL let the user persist selections from Markdown task lists without requiring browser Markdown editing.

#### Scenario: Automatic startup

- **WHEN** the user logs into macOS
- **THEN** the LaunchAgent starts the plan service and keeps it available at the stable local address

#### Scenario: Dashboard use

- **WHEN** the user opens the dashboard
- **THEN** the user can search, filter, render, change status, archive, copy a path, and open a plan in the configured editor

#### Scenario: Interactive Markdown task

- **WHEN** a rendered plan contains a Markdown task item
- **THEN** the dashboard shows an accessible checkbox, and selecting it persists only that task marker in canonical Markdown before refreshing the plan at the same stable URL

#### Scenario: Offline use

- **WHEN** the computer has no internet connection
- **THEN** the dashboard remains fully styled and functional

#### Scenario: Port collision

- **WHEN** another process occupies port 4173
- **THEN** the plan service reports the collision and does not select a different address

### Requirement: Safe Local Web Mutations

The local server MUST validate every request before reading or changing plan files.

#### Scenario: External-origin mutation

- **WHEN** a mutating request has an unexpected Host, Origin, or CSRF token
- **THEN** the server rejects it without changing any file

#### Scenario: Task-toggle validation

- **WHEN** a task-toggle request has an invalid task index, checkbox value, body, or plan revision
- **THEN** the server rejects it without changing canonical Markdown

#### Scenario: Task-toggle revision conflict

- **WHEN** a task-toggle request refers to a plan revision changed by another writer
- **THEN** the server reports a conflict and does not modify a different task

#### Scenario: Path traversal attempt

- **WHEN** a request resolves outside `~/Developer/plans`
- **THEN** the server rejects it without reading or changing the target

#### Scenario: Atomic metadata update

- **WHEN** a status or archive operation succeeds
- **THEN** the resulting Markdown and metadata are complete and no partial file is observable

#### Scenario: Atomic task update

- **WHEN** a task-toggle operation succeeds
- **THEN** only the requested Markdown task marker changes, and no partial file is observable

#### Scenario: Shared mutation serialization

- **WHEN** CLI and dashboard mutations overlap
- **THEN** they use the same library writer lock so revision checks, metadata changes, task changes, and archive moves cannot overwrite one another

#### Scenario: Ownership-safe stale-lock recovery

- **WHEN** many writers encounter a lock left by a crashed process
- **THEN** an atomic lease-backed lock serializes them, stale ownership is reclaimed without removing an active successor's lock, and a dead legacy recovery guard cannot block future mutations
