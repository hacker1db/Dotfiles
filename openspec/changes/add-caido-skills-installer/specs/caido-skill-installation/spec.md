## ADDED Requirements

### Requirement: Explicit project-scoped installation

The system SHALL provide an opt-in command that installs the official Caido skills into an explicitly supplied existing project directory and SHALL NOT install them through the default dotfiles installation flow.

#### Scenario: Install into a selected project

- **WHEN** the user runs the command with a valid project directory
- **THEN** the official `caido/skills` package is installed with project scope inside that directory
- **AND** the Caido skill's Node dependencies are installed locally

#### Scenario: Reject a missing target

- **WHEN** the user omits the project directory or supplies a directory that does not exist
- **THEN** the command exits unsuccessfully without invoking the upstream installer

#### Scenario: Preserve unrelated projects

- **WHEN** the command installs Caido skills into one project directory
- **THEN** it does not add Caido skills to global agent skill directories or any other project

### Requirement: Safe and observable installation

The system SHALL validate required commands, preserve paths containing spaces, propagate installation failures, and report when Git ignore rules hide installed skill files.

#### Scenario: Missing dependency

- **WHEN** a required command is unavailable
- **THEN** the installer exits unsuccessfully with a message identifying the missing command

#### Scenario: Ignored installed files

- **WHEN** Git ignore rules match the installed project-local skill files
- **THEN** the installer completes and warns that the files are ignored

