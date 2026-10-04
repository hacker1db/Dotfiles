## 1. Implementation

- [x] 1.1 Verify installed Claude settings precedence and Azure credential-chain behavior.
- [x] 1.2 Add session-specific Claude subscription and Foundry launchers without global writes.
- [x] 1.3 Support explicit endpoints and deployments and reject ambiguous discovery.
- [x] 1.4 Verify concurrent sessions, argument forwarding, credential cleanup, failure handling, and preservation of statusLine and global credentials with CLI stubs.
- [x] 1.5 Document commands, setup, and supported CLI scope.
- [x] 1.6 Run syntax checks and focused tests and validate a live Foundry session where account access permits.

## Validation result

Concurrent stubbed sessions, credential cleanup, custom deployment selection, explicit endpoints, ambiguous/missing resources, login failure, argument forwarding, global-file preservation, temporary-file cleanup, and exit-code propagation passed. Bash syntax checks, OpenSpec validation, and diff whitespace checks passed. The installed Claude CLI started through `claude-subscription --version`. Azure account metadata was readable, but live resource discovery failed with AADSTS9002313 and requested interactive reauthentication, so live Foundry inference remains unverified.
