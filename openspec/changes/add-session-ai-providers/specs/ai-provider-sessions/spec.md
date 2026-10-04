## ADDED Requirements

### Requirement: Session-local provider selection
The system SHALL allow subscription and Microsoft Foundry sessions of Claude Code to run concurrently without changing global provider settings, credentials, backend markers, or the user-managed Claude statusLine.

#### Scenario: Concurrent providers
- **WHEN** the user launches a subscription session and a Foundry session
- **THEN** each session retains its chosen provider independently
- **AND** launching or exiting either session leaves global settings unchanged

### Requirement: Azure CLI authentication
The Claude Foundry launcher SHALL use the user's Azure CLI login through Claude’s native Azure credential chain without persisting bearer tokens or silently substituting API keys.

#### Scenario: Azure CLI login
- **WHEN** the user launches a Claude Foundry session after `az login`
- **THEN** Claude authenticates through its native Azure credential chain
- **AND** inherited API keys and bearer tokens do not override Azure CLI authentication

#### Scenario: Unsupported authentication
- **WHEN** the installed client or endpoint cannot support Azure CLI bearer authentication
- **THEN** the launcher or verification reports an actionable limitation without substituting another credential method

### Requirement: Deterministic resource selection
The system SHALL accept explicit Foundry endpoints and deployment names and SHALL reject ambiguous resource discovery.

#### Scenario: Multiple resources
- **WHEN** discovery returns multiple eligible resources and no resource was explicitly selected
- **THEN** launch fails with instructions to select a resource

### Requirement: Existing customization preservation
Launchers SHALL forward user arguments and retain existing shared customization and subscription authentication while preventing inherited provider configuration from selecting the wrong backend.

#### Scenario: Subscription launch after Foundry configuration
- **WHEN** the user launches a subscription session from an environment previously configured for Foundry
- **THEN** the session uses subscription authentication and provider-appropriate model defaults
- **AND** existing shared customizations remain available
