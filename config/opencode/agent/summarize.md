# Documentation Summarizer

**Command:** `/summarize`  
**Aliases:** `/sum`, `/tldr`  
**Provider:** Anthropic Claude Sonnet  
**Type:** Secondary Agent

## Purpose

Multi-layered documentation summarization with hierarchical section mapping, key concept extraction, and follow-up Q&A.

## Configuration

```yaml
model:
  provider: anthropic
  name: claude-opus-4-6
  temperature: 0.2
  max_tokens: 4096

input:
  max_file_size_mb: 5
  supported_formats:
    - md
    - rst
    - txt
    - pdf
```

## System Prompt

```
You are a technical documentation expert specializing in distillation and summarization.

Provide:
- Executive Summary (2-3 sentences)
- Section Map (hierarchical outline with key points)
- Key Concepts (definitions, important terms)
- TL;DR (one-sentence takeaway)
- Follow-up Questions (3-5 clarifying questions)

Preserve technical accuracy. Use clear, concise language.
```

## Output Format

```markdown
# Summary: Docker Compose Documentation

## TL;DR
Docker Compose is a tool for defining and running multi-container Docker applications using YAML configuration files.

## Executive Summary
Docker Compose simplifies orchestration of multi-container applications by allowing developers to define services, networks, and volumes in a single `docker-compose.yml` file. It handles dependency ordering, networking, and environment variable management, making it ideal for development and testing environments. Production deployments typically migrate to Kubernetes or Docker Swarm.

## Section Map

### 1. Introduction
- Purpose: Orchestrate multi-container apps
- Core concept: Infrastructure as Code via YAML
- Use cases: Development, testing, simple production

### 2. Installation
- **Linux**: `curl` + binary download
- **Mac/Windows**: Included with Docker Desktop
- Version compatibility: Match Docker Engine version

### 3. Configuration (docker-compose.yml)

#### 3.1 Services
- Container definitions
- Image source (build vs. pull)
- Port mappings: `ports: ["3000:3000"]`
- Environment variables: `environment:` or `env_file:`

#### 3.2 Networks
- Default bridge network created automatically
- Custom networks: `driver: bridge|overlay`
- Inter-service communication by service name

#### 3.3 Volumes
- Named volumes for persistence
- Bind mounts for development
- Volume drivers for cloud storage

### 4. Commands
- `docker-compose up`: Start services
- `docker-compose down`: Stop and remove
- `docker-compose logs`: View logs
- `docker-compose ps`: List containers

### 5. Best Practices
- Use `.env` files for secrets
- Pin image versions (avoid `:latest`)
- Separate configs for dev/prod
- Use health checks for dependencies

## Key Concepts

**Service**: A containerized application component defined in `docker-compose.yml`. Can scale to multiple instances.

**Network**: Isolated communication layer. Services on the same network can resolve each other by name.

**Volume**: Persistent storage that survives container restarts. Can be named (managed by Docker) or bind mounts (host filesystem).

**Dependency**: Service startup order defined via `depends_on`. Note: Only waits for container start, not application readiness.

**Override**: `docker-compose.override.yml` extends base config without modifying it. Useful for local development settings.

## Follow-up Questions

1. How do you handle database migrations on container startup?
2. What's the recommended approach for secrets management (beyond `.env` files)?
3. How do you implement zero-downtime deployments with Compose?
4. What are the limitations of `depends_on` vs. proper health checks?
5. When should you migrate from Compose to Kubernetes?

## File Reference
**Source**: `/docs/docker-compose.md`  
**Length**: 3,421 words  
**Last modified**: 2024-10-15
```

## Usage

```bash
# Summarize a file
/summarize README.md

# Summarize with alias
/sum docs/architecture.md

# Quick TL;DR
/tldr CONTRIBUTING.md

# Summarize from URL
/summarize https://docs.docker.com/compose/
```

## Supported Formats

- **Markdown** (`.md`)
- **reStructuredText** (`.rst`)
- **Plain Text** (`.txt`)
- **PDF** (`.pdf`) - Experimental

## Multi-File Summarization

```bash
# Summarize entire directory
/summarize docs/

# Output: Combined summary with cross-references
```

## Rate Limiting

- **Requests per minute**: 20
- **Burst size**: 5

## Caching

- **Enabled**: Yes
- **TTL**: 3600 seconds (1 hour)

## Environment Variables

```bash
export ANTHROPIC_API_KEY="your-anthropic-key"
```

## Capabilities

- Single file summarization
- Multi-file summarization
- Hierarchical structuring
- Concept extraction
- Question generation
