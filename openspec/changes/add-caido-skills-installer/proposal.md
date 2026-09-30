## Why

Caido skills are only useful in selected security projects, while the current dotfiles skill linker installs managed skills globally. A project-scoped command is needed so a caller can opt a specific directory into the official Caido skills without affecting other projects.

## What Changes

- Add an `install-caido-skills <project-directory>` command to install the official `caido/skills` repository into one project.
- Require an explicit existing target directory and keep the upstream installation project-scoped.
- Install the Caido skill's Node dependencies after the upstream skills installer completes.
- Document the command without adding it to the default dotfiles installation flow.
- Warn when the installed project files are hidden by Git ignore rules.

## Impact

- Affected specs: `caido-skill-installation`
- Affected code: `bin/install-caido-skills`, `README.md`
- External tools: `pnpm`, `npm`, `git`, `caido/skills`, and the Vercel skills CLI

