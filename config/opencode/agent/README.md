# OpenCode Global Agents

Custom agent configurations for OpenCode CLI.

## Overview

Agents are specialized AI assistants that can be invoked via slash commands to perform specific tasks like code review, security scanning, commit message generation, and more.

## Available Agents

### Primary Agents

#### Code Reviewer (`/review`)
**Provider:** GitHub Copilot  
**Purpose:** Comprehensive code review with security, performance, and maintainability analysis

Features:
- Multi-dimensional rubric (correctness, security, performance, clarity, maintainability, style)
- Severity-based findings (critical, high, medium, low, info)
- Inline patch suggestions
- Secret detection and redaction
- Integration with linters and static analysis tools

Usage:
```bash
# Review staged changes
/review

# Review with strict mode
/review --strict

# Output as JSON
/review --json
```

### Secondary Agents

#### Security Review (`/security-review`)
**Provider:** Anthropic Claude  
**Purpose:** Security-focused vulnerability scanning and advisory

Features:
- SAST integration (Semgrep, Trivy, Gitleaks)
- Dependency vulnerability checking
- Secret exposure detection
- CVSS-based severity scoring

Usage:
```bash
/security-review
/sec
```

#### Commit Assistant (`/commit-msg`)
**Provider:** Anthropic Claude Haiku  
**Purpose:** Generate conventional commit messages

Features:
- Conventional commits format
- 3 message variants (concise, detailed, with body)
- Branch context awareness
- Commit history style learning

Usage:
```bash
/commit-msg
/commit
```

#### PR Reviewer (`/pr-review`)
**Provider:** Anthropic Claude Sonnet  
**Purpose:** Comprehensive pull request analysis

Features:
- Multi-commit synthesis
- Risk assessment
- Breaking change detection
- Testing recommendations
- Deployment notes

Usage:
```bash
/pr-review
/pr
```

#### Knowledge Retrieval (`/search-notes`)
**Provider:** Anthropic Claude Sonnet  
**Purpose:** Semantic search across Obsidian vault and Readwise highlights

Features:
- Hybrid keyword + embedding search
- FAISS vector index
- Incremental indexing
- Citation with source references

Usage:
```bash
/search-notes "How do I configure Azure APIM?"
/knowledge "DevSecOps best practices"
```

#### Documentation Summarizer (`/summarize`)
**Provider:** Anthropic Claude Sonnet  
**Purpose:** Multi-layered document summarization

Features:
- Executive summary
- Hierarchical section mapping
- Key concept extraction
- TL;DR generation

Usage:
```bash
/summarize README.md
/tldr docs/architecture.md
```

#### Refactor Assistant (`/refactor`)
**Provider:** Anthropic Claude Sonnet  
**Purpose:** Safe code refactoring with semantic preservation

Features:
- Semantic equivalence verification
- Test impact analysis
- Diff proposal generation
- Risk assessment

Usage:
```bash
/refactor "Extract this function into smaller utilities"
```

## Configuration

### Agent Schema

Each agent is defined in a YAML file with the following structure:

```yaml
name: agent-name
version: 1.0.0
description: Agent description
primary: true|false
enabled: true|false

trigger:
  command: /command
  aliases: [/alt1, /alt2]
  auto_suggest: true|false

model:
  provider: anthropic|openai|copilot|local
  name: model-id
  params:
    temperature: 0.2
    top_p: 0.9
    max_tokens: 4096

prompts:
  system: |
    System prompt
  user_template: |
    User prompt with ${VARIABLES}
```

See `schema.yaml` for complete specification.

### Environment Variables

#### GitHub Copilot
```bash
export COPILOT_TOKEN="your-github-copilot-token"
```

#### Anthropic
```bash
export ANTHROPIC_API_KEY="your-anthropic-key"
```

#### OpenAI (for embeddings)
```bash
export OPENAI_API_KEY="your-openai-key"
```

### Variable Interpolation

Prompts support variable substitution:

- `${WORKSPACE_ROOT}` - Current workspace path
- `${REPO_NAME}` - Git repository name
- `${BRANCH_NAME}` - Current branch
- `${GIT_DIFF}` - Staged diff
- `${FILE_PATH}` - Target file path
- `${LANGUAGE}` - Detected language
- `${CHUNK_INDEX}` - Current chunk number
- `${TOTAL_CHUNKS}` - Total chunks
- Custom variables defined in agent config

## Security

### Secret Redaction

All agents automatically redact patterns matching:
- AWS credentials
- API keys
- Passwords
- Tokens
- Private keys

### Path Restrictions

Agents can only access files within:
- `${WORKSPACE_ROOT}/**`

Excluded by default:
- `.git/`
- `node_modules/`
- `vendor/`
- `.env*`

### Telemetry

Telemetry is **opt-in** and excludes:
- File paths
- Code content
- User information

Enable with:
```bash
export OPENCODE_TELEMETRY=true
```

## Creating Custom Agents

1. Create a new YAML file in `~/.dotfiles/config/opencode/agents/`
2. Follow the schema in `schema.yaml`
3. Define unique trigger command
4. Configure model and prompts
5. Test with `opencode agent validate my-agent.yaml`

Example minimal agent:

```yaml
name: my-agent
version: 1.0.0
description: My custom agent
primary: false
enabled: true

trigger:
  command: /my-command

model:
  provider: anthropic
  name: claude-3-5-sonnet-20241022
  params:
    temperature: 0.5
    max_tokens: 2048

prompts:
  system: You are a helpful assistant.
  user_template: ${USER_INPUT}

rate_limit:
  requests_per_minute: 30
  burst_size: 5

cache:
  enabled: true
  ttl_seconds: 3600
```

## Installation

Move these files to your OpenCode config directory:

```bash
# Create directory if it doesn't exist
mkdir -p ~/.dotfiles/config/opencode/agents

# Move agent configs
mv global-agents/*.yaml ~/.dotfiles/config/opencode/agents/
```

Or symlink for easier updates:

```bash
ln -s ~/notes/SecondBrain/global-agents ~/.dotfiles/config/opencode/agents
```

## Troubleshooting

### Agent Not Found
- Ensure YAML file is in `~/.dotfiles/config/opencode/agents/`
- Check `enabled: true` in config
- Verify trigger command is unique

### Authentication Errors
- Verify environment variables are set
- Check token expiration
- Ensure correct provider credentials

### Rate Limiting
- Agents have built-in rate limits
- Exponential backoff on 429 errors
- Check provider-specific quotas

### Cache Issues
- Clear cache: `rm -rf ~/.config/opencode/cache/`
- Disable cache: set `cache.enabled: false`

## Performance

### Optimization Tips

1. **Enable Caching**: Reduces redundant API calls
2. **Chunk Large Diffs**: Set appropriate `max_chunk_lines`
3. **Use Haiku for Simple Tasks**: Faster, cheaper for commit messages
4. **Batch Reviews**: Review multiple files together when possible

### Metrics

Monitor agent performance:
```bash
opencode agent stats
```

## Contributing

To contribute new agents:

1. Fork the repository
2. Create agent YAML in `agents/`
3. Add documentation
4. Submit PR with test cases

## License

MIT

## Support

- Issues: https://github.com/sst/opencode/issues
- Discussions: https://github.com/sst/opencode/discussions
