## Context

The existing `plan` CLI and dashboard are local-only. The hosted command surface is intentionally unavailable until a private service is deployed. The hosted service will be a single-owner Next.js application on Vercel; it is not a public sharing site or a multi-tenant product.

## Goals / Non-Goals

- Goals: default-deny hosted access, private Markdown storage, one owner browser identity, revocable CLI upload credentials, stable authenticated plan URLs, and no Vercel platform credentials outside Vercel.
- Non-Goals: anonymous viewing, public sign-up, shared workspaces, invitation management, browser editing, public Blob URLs, or automatic local-to-hosted synchronization.

## Decisions

### Browser identity and authorization

Use Clerk with `PLAN_MANAGER_OWNER_CLERK_USER_ID` as the one authorized browser identity. Middleware requires Clerk authentication for every page route other than the Clerk sign-in flow. A server-side authorization helper verifies that the session user ID equals the configured owner ID before any page renders or any browser API returns plan data.

The service fails closed when Clerk keys or the owner user ID are absent. It provides no sign-up route; Clerk instance settings must disable public sign-up. A valid Clerk session for any other account receives `403` and never learns whether a plan exists.

### CLI authorization

Browser sessions and CLI credentials are separate. `plan auth login` provisions a scoped plan-manager token through an owner-authorized flow. The CLI stores the secret in the macOS Keychain and sends it only to `Authorization: Bearer` on versioned upload endpoints. The service stores an identifier, scope, expiry, revocation timestamp, and a salted token hash in Postgres. It never stores plaintext tokens and never accepts Vercel, Clerk, Blob, database, or deployment-protection secrets as CLI credentials.

API routes accept either the owner browser session or a valid scoped CLI token as appropriate. Middleware cannot replace route-level checks because API uploads need non-browser token authentication.

### Private data and deployment protection

Markdown is written to private Vercel Blob paths. Pages and downloads resolve the object server-side only after authorization; no response includes a raw Blob URL. Metadata and ownership/revision records live in Neon Postgres, provisioned through the Vercel Marketplace. The first-party Vercel Postgres package is sunset and is not used.

Application authorization is required even when Vercel Deployment Protection is enabled. Deployment Protection is optional defense in depth: it can restrict browser traffic at Vercel, but a protected upload API requires a distinct automation-bypass secret. If enabled, that secret remains in the Keychain and is never used as the application CLI credential.

### Hosted visual identity

The generated plan-document favicon is placed at `hosted/app/icon.png`, referenced through Next.js metadata, and has no embedded text or external asset dependency.

## Risks / Trade-offs

- The owner Clerk user ID cannot be known until the user first signs in. Deployment is intentionally blocked until it is configured.
- A CLI token can upload only with its explicit scope and expiry; token creation and revocation require the owner session.
- Vercel Deployment Protection can add cost and requires separate automation configuration; it does not replace application authorization.

## Migration Plan

1. Scaffold the hosted application and private authorization helpers without changing local behavior.
2. Provision Clerk, sign in as the owner, record only the Clerk user ID in Vercel environment configuration, and disable public sign-up.
3. Provision private Blob and Postgres bindings.
4. Deploy with required-environment checks and verify unauthorized requests cannot render or fetch content.
5. Configure an explicit hosted remote and provision a scoped CLI credential.
