## 1. Hosted application and identity

- [x] 1.1 Scaffold the separate TypeScript Next.js hosted application, metadata, generated favicon, and fail-closed environment validation.
- [x] 1.2 Integrate Clerk sign-in and owner-only authorization helpers; disable public sign-up and reject non-owner sessions.
- [x] 1.3 Add middleware for browser routes and route-level authorization for every page and API handler.

## 2. Private persistence and CLI access

- [x] 2.1 Add private Blob and Neon Postgres persistence for plan versions, ownership, revisions, and token records.
- [x] 2.2 Implement scoped, expiring, revocable CLI credentials with hashed server-side storage and macOS Keychain integration.
- [x] 2.3 Implement authenticated versioned upload, list, plan detail, and download handlers without exposing private Blob URLs.

## 3. Verification and deployment

- [ ] 3.1 Add tests for unauthenticated, wrong-user, expired, revoked, and insufficient-scope requests; assert no metadata or Blob URL leaks.
- [ ] 3.2 Add tests for owner browser access, CLI upload conflict handling, token rotation, sanitization, and private download behavior.
- [ ] 3.3 Document Vercel/Clerk provisioning, owner ID configuration, Deployment Protection trade-offs, Keychain storage, and secure rollback.
