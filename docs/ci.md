# CI and security scanning

`.github/workflows/ci.yml` runs on pushes to `main` and on pull requests: `zsh -n` over `install.sh`, `install/*.zsh`, and the Zsh configuration, plus Luacheck over the Neovim config (ignoring existing unused-variable and line-length warnings). A `secrets` job scans the full history with TruffleHog, pinned to a commit SHA, and fails on any finding, verified or unverified; false alarms get an exclude file reviewed in the PR. On pull requests, dependency review fails if a change adds a dependency with a known vulnerability of any severity.

`.github/workflows/codeql.yml` runs CodeQL `security-extended` queries for GitHub Actions and JavaScript/TypeScript on pushes to `main`, on pull requests, and weekly. `.github/dependabot.yml` opens update pull requests for npm, Docker, and pinned GitHub Actions. Every action is pinned to a commit SHA.
