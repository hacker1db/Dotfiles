# Example Decision Patterns

## Broad deployer identity
Convert “the identity has too much access” into testable outcomes:
- Split unrelated deployment duties into bounded execution planes.
- Scope each identity to resources it owns.
- Remove create/delete authority outside that boundary.
- Use federated identity instead of stored credentials where supported.
- Preserve distinct audit trails for each deployment plane.

## Delivery deadline with unresolved risk
- Identify the two or three controls that cannot be deferred.
- Define compensating controls for remaining gaps.
- Record a risk owner, milestones, and expiration date.
- State what evidence closes the exception.

## Privileged operations
- Use a constrained human-access path for immediate needs.
- Prefer PIM or equivalent just-in-time elevation.
- Restrict role assignment to an approved role set and scope.
- Track recurring actions and move them to automation as the target state.
