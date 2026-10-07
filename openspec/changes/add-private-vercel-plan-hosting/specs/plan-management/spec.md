## ADDED Requirements

### Requirement: Single-Owner Hosted Access

The hosted plan service SHALL deny access by default and SHALL authorize browser access only for the Clerk user ID configured as its single owner.

#### Scenario: Unauthenticated request

- **WHEN** a browser requests a hosted plan page or browser API without a Clerk session
- **THEN** it is redirected to sign in or receives `401`, and no plan metadata or content is returned

#### Scenario: Wrong authenticated user

- **WHEN** an authenticated Clerk user does not match `PLAN_MANAGER_OWNER_CLERK_USER_ID`
- **THEN** the service returns `403` without revealing whether any plan exists

#### Scenario: Missing owner configuration

- **WHEN** required Clerk configuration or the owner user ID is absent
- **THEN** the hosted service fails closed and does not render plan content or accept uploads

### Requirement: Separate Scoped CLI Credentials

The hosted plan service SHALL use independently revocable, scoped, and expiring CLI credentials for non-browser plan operations.

#### Scenario: Valid plan upload

- **WHEN** the local CLI supplies a valid unexpired credential with plan-write scope and an expected revision
- **THEN** the hosted API authorizes the upload without requiring a browser session and returns the authenticated stable plan URL

#### Scenario: Expired or revoked credential

- **WHEN** a CLI credential is expired, revoked, malformed, or lacks the required scope
- **THEN** the API returns `401` or `403` and does not read or modify hosted plan data

### Requirement: Private Hosted Plan Storage

The hosted plan service SHALL retain Markdown in private object storage and SHALL never expose object-storage URLs to clients.

#### Scenario: Authorized plan view

- **WHEN** the owner views or downloads a hosted plan
- **THEN** the server authorizes the request before reading the private object and returns sanitized content without a Blob URL

#### Scenario: Unauthorized plan identifier

- **WHEN** an unauthorized requester guesses a hosted plan ID
- **THEN** the service returns no plan metadata, Markdown, revision, or object-storage locator

### Requirement: Hosted Favicon

The hosted plan service SHALL provide an owner-managed favicon without a remote image dependency.

#### Scenario: Hosted page metadata

- **WHEN** a browser loads any hosted plan page
- **THEN** it receives the packaged plan-document favicon through the application metadata
